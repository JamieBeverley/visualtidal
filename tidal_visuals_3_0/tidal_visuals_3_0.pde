import java.util.Collections;
//import java.util.List;
import java.util.*;

import oscP5.*;
import netP5.*;
import lord_of_galaxy.timing_utils.*;


OscP5 osc;
NetAddress myRemoteLocation;

Stopwatch stopwatch;

int oscPort = 9000;

String codeText = "";

int iterCount = 0;

float textLeft;
float textTop;
float textWidth;
float textHeight;

float currentTime;
//ArrayList<Synth> createList = new ArrayList<Synth>(20); // For newly instantiated synths
//List<Synth> existingList = Collections.synchronizedList(new ArrayList<Synth>()); // For synths that exist/are still playing/visible

//LinkedList<Drawable> drawQueue = new LinkedList<Drawable>();

List<Drawable> drawQueue = Collections.synchronizedList(new LinkedList<Drawable>());


void setup() {
  DrawOrbit.drawOrbits = new DrawOrbit[] {new DrawOrbit(new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000), new DrawOrbit(new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000), new DrawOrbit(new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000)};

  fullScreen(P2D, 1);
  //size(800,600);

  OscProperties op = new OscProperties();
  op.setListeningPort(oscPort);
  op.setDatagramSize(20000);
  osc = new OscP5(this, op);


  textSize(36);

  textLeft = 0.05*width;
  textTop = 0.05*height;
  textWidth = 0.9*width;
  textHeight = 0.9*height;

  rectMode(CORNER);

  stopwatch = new Stopwatch(this);
  stopwatch.start();
  currentTime = stopwatch.time();
}


void draw() {
  fill(0, 0, 0);
  rect(0, 0, width-1, height-1);
  currentTime = stopwatch.time();

  synchronized(drawQueue) {
    Iterator<Drawable> iterator = drawQueue.iterator();
    while (iterator.hasNext()) {
      Drawable d = iterator.next();
      if (d.expireTime < currentTime) {
        iterator.remove();
      } else {
        d.draw(currentTime);
      }
    }
  }
  //if(iterCount %20==0){
  //  println(drawQueue.size());
  //}

  fill(255, 255, 255);
  rotate(0);
  text(codeText, textLeft, textTop, textWidth, textHeight);
  iterCount++;
}

/*
shapes:
 rect, ellipse (circle as tidal alias), triangle, polygon
 
 rect: (x, y, w, h)
 ellipse: (x,y,w,h)
 arc (x,y, w, h, start, stop) -- start/stop are in radians but should translate to from 0-1 as consistent with tidal
 
 drawOrbits:
 color, translateable?, 
 tidal: setColor 0 (orbit) ("20","0","255"). - Default orbit things are placed in is 1. 8 orbits
 */

LinkedList<Drawable> parseMessage (Object[] args) {

  LinkedList<Drawable> r = new LinkedList<Drawable>();
  //HashMap<String,Object> recSpecs = new HashMap<String,Object>();
  //HashMap<String,Object> ellipseSpecs = new HashMap<String,Object>();
  //HashMap<String,Object> arcSpecs = new HashMap<String,Object>();
  HashMap<String, Object> params = new HashMap<String, Object>();

  float currentTime = stopwatch.time();
  Rect rec = new Rect();
  Ellipse el = new Ellipse();
  Arc arc = new Arc();


  color oc;
  // TODO r/softwaregore
  for (int i =0; i < args.length-1; i+=2) {
    params.put(args[i].toString(), args[i+1]);
  }

  DrawOrbit drawOrbit = DrawOrbit.drawOrbits[(int)params.getOrDefault("drawOrbit", 0)];
  params.put("drawOrbit", drawOrbit);

  setOrbitParams(params);
  params.put("expireTime", currentTime+drawOrbit.sustain);
  params.put("startTime", currentTime);

  if (rec.isDefined(params)) {
    println("adding rect");
    r.add(new Rect(params));
    println("test");
  }
  if (el.isDefined(params)) {
    r.add(new Ellipse(params));
  }
  if (arc.isDefined(params)) {
    r.add(new Arc(params));
  }

  return r;
} // End parse osc

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage msg) {

  if (msg.checkAddrPattern("/tidal")) {

    drawQueue.addAll(parseMessage(msg.arguments()));
  } else if (msg.checkAddrPattern("/atom/text")) {
    codeText = msg.get(0).stringValue();
  } else {
    println("WARNING - Unhandled OSC message: "+msg.addrPattern());
  }
  /* print the address pattern and the typetag of the received OscMessage */
  println("### received osc message:" + msg.addrPattern() +" "+msg.arguments());
}



class Ellipse extends Drawable {
  public PVector pos;
  public PVector dimensions;
  public float rotation;

  Ellipse () {
  }

  Ellipse (int x, int y, int w, int h, float rotation) {
    this.pos = new PVector(x, y);
    this.dimensions = new PVector(w, h);
    this.rotation = rotation;
  }

  Ellipse (HashMap<String, Object> d) {
    pos = new PVector(parseWidthParam(d.get("ellipseX")), parseHeightParam(d.get("ellipseY")));
    dimensions = new PVector(parseWidthParam(d.get("ellipseW")), parseHeightParam(d.get("ellipseH")));
    rotation = parseRotation((float)d.getOrDefault("ellipseRotation", 0.0f));    
    
    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    expireTime = (float)d.get("expireTime");
    startTime = (float)d.get("startTime");
  }

  void draw(float time) {
    pushMatrix();
    translate(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y);
    rotate(rotation+this.drawOrbit.rotation);

    rotate(rotation+this.drawOrbit.rotation);
    float dur = expireTime-startTime;
    
    color col = lerpColor(this.drawOrbit.c.toColor(), color(this.drawOrbit.c.r,this.drawOrbit.c.g, this.drawOrbit.c.b, 0), (time-startTime)/dur);
    fill (col);
    stroke(this.drawOrbit.c.toColor());
    //ellipse(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y,dimensions.x,dimensions.y);
    ellipse(0, 0, dimensions.x, dimensions.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("ellipseX")&&d.containsKey("ellipseY")&&d.containsKey("ellipseW")&&d.containsKey("ellipseH");
  }
}// end Ellipse






class Arc extends Drawable {
  public PVector pos;
  public PVector dimensions;
  public PVector trace; //start/stop in processing arc documentation
  public float rotation;

  Arc () {
  }

  Arc (HashMap<String, Object> d) {
    println("before pos");
    pos = new PVector((int)d.get("arcX"), (int)d.get("arcY"));
    println("before dim");
    dimensions = new PVector((int)d.get("arcW"), (int)d.get("arcH"));
    println("before trace");
    print(d.get("arcStart"));
    trace = new PVector((float)d.get("arcStart"), (float)d.get("arcStop"));
    rotation = (float)d.getOrDefault("arcRotation", 0.0f);
    println("here1");
    println(d.get("drawOrbit"));
    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    println("here2");
    expireTime = (float)d.get("expireTime");
    println("here3");
    startTime = (float)d.get("startTime");
  }

  void draw(float time) {
    pushMatrix();
    translate(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y);
    rotate(rotation+this.drawOrbit.rotation);
    float dur = expireTime-startTime;
    color col = lerpColor(this.drawOrbit.c.toColor(), color(this.drawOrbit.c.r,this.drawOrbit.c.g, this.drawOrbit.c.b, this.drawOrbit.c.a), (time-startTime)/dur);
    fill(col);
    stroke(col);
    arc(0, 0, dimensions.x, dimensions.y, trace.x, trace.y);
    //arc(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y,dimensions.x,dimensions.y, trace.x,trace.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("arcX")&&d.containsKey("arcY")&&d.containsKey("arcW")&&d.containsKey("arcH")&&d.containsKey("arcStart")&&d.containsKey("arcStop");
  }
} // end Rect


class Rect extends Drawable {
  public PVector pos;
  public PVector dimensions;
  public float rotation;

  Rect () {
  }

  Rect(color c, PVector pos, PVector dimensions, float rot) {
    this.pos=pos;
    this.dimensions=dimensions;
    this.rotation=rot;
  }

  Rect (HashMap<String, Object> d) {
    
    pos = new PVector(parseWidthParam(d.get("rectX")), parseHeightParam(d.get("rectY")));
    
    dimensions = new PVector(parseWidthParam(d.get("rectW")), parseHeightParam(d.get("rectH")));
    rotation = parseRotation((float)d.getOrDefault("rectRotation", 0.0f));
    
    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    
    expireTime = (float)d.get("expireTime");
    startTime = (float)d.get("startTime");
    
  }

  void draw(float time) {

    pushMatrix();
    translate(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y);
    rotate(rotation+this.drawOrbit.rotation);

    rotate(rotation+this.drawOrbit.rotation);
    float dur = expireTime-startTime;
    color col = lerpColor(this.drawOrbit.c.toColor(), color(this.drawOrbit.c.r,this.drawOrbit.c.g, this.drawOrbit.c.b, 0), (time-startTime)/dur);
    fill(col);
    stroke(this.drawOrbit.c.toColor());
    //rect(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y,dimensions.x,dimensions.y);
    rect((-1)*this.dimensions.x/2, (-1)*this.dimensions.y/2, dimensions.x, dimensions.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("rectX")&&d.containsKey("rectY")&&d.containsKey("rectW")&&d.containsKey("rectH");
  }
} // end Rect

abstract class Drawable {
  DrawOrbit drawOrbit;
  float expireTime;
  float startTime;

  abstract boolean isDefined(HashMap<String, Object> d);

  abstract void draw(float time);
}


static class DrawOrbit {
  public static DrawOrbit[] drawOrbits;
  Color c;
  float rotation;
  PVector translation;
  float sustain;
  
  
  DrawOrbit(Color c, float rotation, PVector translation, float sustain) {
    this.c = c;
    this.rotation = rotation;
    this.translation = translation;
    this.sustain = sustain;
  }
}

class Color {
  int r;
  int g;
  int b;
  int a;
  Color (int r, int g, int b, int a) {
    this.r = r;
    this.g = g;
    this.b = b;
    this. a = a;
  }
  color toColor() {
    return (color(r, g, b, a));
  }
}


void setOrbitParams(HashMap<String, Object> params) {
  Object[] keys = params.keySet().toArray();
  //Color c = color(0,0,0);
  color oc;
  for (int i =0; i<keys.length; i++) {
    String paramKey = keys[i].toString();
    switch (paramKey) {
    case "colorR0": 
      DrawOrbit.drawOrbits[0].c.r = parseColorComponent(params.get(paramKey));
      break;
    case "colorG0": 
      DrawOrbit.drawOrbits[0].c.g = parseColorComponent(params.get(paramKey));
      break;
    case "colorB0": 
      DrawOrbit.drawOrbits[0].c.b = parseColorComponent(params.get(paramKey));
      break;
    case "colorR1": 
      DrawOrbit.drawOrbits[1].c.r = parseColorComponent(params.get(paramKey));
      break;
    case "colorG1": 
      DrawOrbit.drawOrbits[1].c.g = parseColorComponent(params.get(paramKey));
      break;
    case "colorB1": 
      DrawOrbit.drawOrbits[1].c.b = parseColorComponent(params.get(paramKey));
      break;
    case "colorR2": 
      DrawOrbit.drawOrbits[2].c.r = parseColorComponent(params.get(paramKey));
      break;
    case "colorG2": 
      DrawOrbit.drawOrbits[2].c.g = parseColorComponent(params.get(paramKey));
      break;
    case "colorB2": 
      DrawOrbit.drawOrbits[2].c.b = parseColorComponent(params.get(paramKey));
      break;

    case "translateX0": 
      DrawOrbit.drawOrbits[0].translation.x = parseWidthTranslation(params.get(paramKey));
      break;
    case "translateY0": 
      DrawOrbit.drawOrbits[0].translation.y = parseHeightTranslation(params.get(paramKey));
      break;
    case "rotate0": 
      DrawOrbit.drawOrbits[0].rotation = parseRotation(params.get(paramKey));
      break;

    case "translateX1": 
      DrawOrbit.drawOrbits[1].translation.x = parseWidthTranslation(params.get(paramKey));
      break;
    case "translateY1": 
      DrawOrbit.drawOrbits[1].translation.y = parseHeightTranslation(params.get(paramKey));
      break;
    case "rotate1": 
      DrawOrbit.drawOrbits[1].rotation = parseRotation(params.get(paramKey));
      break;

    case "translateX2": 
      DrawOrbit.drawOrbits[2].translation.x = parseWidthTranslation(params.get(paramKey));
      break;
    case "translateY2": 
      DrawOrbit.drawOrbits[2].translation.y = parseHeightTranslation(params.get(paramKey));
      break;
    case "rotate2": 
      DrawOrbit.drawOrbits[2].rotation = parseRotation(params.get(paramKey));
      break;
      
     case "drawSustain0":
       DrawOrbit.drawOrbits[0].sustain = parseSustain(params.get(paramKey));
       break;
     case "drawSustain1":
       DrawOrbit.drawOrbits[1].sustain = parseSustain(params.get(paramKey));
       break;
     case "drawSustain2":
       DrawOrbit.drawOrbits[2].sustain = parseSustain(params.get(paramKey));
       break;
    }
  }
}

float parseSustain(Object value){
 return (float)value*1000; // in ms 
}

int parseColorComponent(Object value) {  
  return (int)Math.floor(255*(float)value);
}

int parseWidthParam (Object value){
  return (int)Math.floor((float)value*width);
}

int parseHeightParam (Object value){
  return (int)Math.floor((float)value*height);
}

float parseWidthTranslation(Object value) {
  return (width * 2* ((float) value)-1)/2;
}

float parseHeightTranslation(Object value) {
  return (height  * 2* ((float) value)-1)/2;
}

float parseRotation (Object value){
  return PI*((float)value);
}