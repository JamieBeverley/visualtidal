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

List<Drawable> drawQueue = Collections.synchronizedList(new LinkedList<Drawable>());

DrawOrbit[] drawOrbits = {
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000,new PVector(0,0)), 
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000, new PVector(0,0)), 
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000,new PVector(0,0)),
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000,new PVector(0,0)), 
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000, new PVector(0,0)), 
  new DrawOrbit(new Color(0, 0, 0, 255), new Color(0, 0, 0, 255), 0, new PVector(0, 0),1000,new PVector(0,0))
};

void setup() {
  
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
  HashMap<String, Object> params = new HashMap<String, Object>();

  float currentTime = stopwatch.time();
  Rect rec = new Rect();
  Ellipse el = new Ellipse();
  Arc arc = new Arc();
  Grid grid = new Grid();
  Line line = new Line();

  for (int i =0; i < args.length-1; i+=2) {
    params.put(args[i].toString(), args[i+1]);
  }

  DrawOrbit drawOrbit = drawOrbits[(int)params.getOrDefault("drawOrbit", 0)];

  params.put("drawOrbit", drawOrbit);

  drawOrbit.setOrbitParams(params);

  //setOrbitParams(drawOrbit, params);
  params.put("expireTime", currentTime+drawOrbit.sustain);
  params.put("startTime", currentTime);

  if(grid.isDefined(params)){
    r.add(new Grid(params));
  }
  
  if(line.isDefined(params)){
    r.add(new Line(params));
  }

  if (rec.isDefined(params)) {
    r.add(new Rect(params));
  }
  if (el.isDefined(params)) {
    r.add(new Ellipse(params));
  }
  if (arc.isDefined(params)) {
    r.add(new Arc(params));
  }
  //println(r);

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
  //println("### received osc message:" + msg.addrPattern() +" "+msg.arguments());
}

class Grid extends Drawable {
  int numX;
  int numY;
  Drawable fundamental;
  String shapeType; //TODO
  Drawable[][] drawables;
  
  Grid (){}
  
  Grid(HashMap <String, Object> d){
    numX = (int)d.get("gridNumX");
    numY = (int)d.get("gridNumY");
    expireTime = (float)d.get("expireTime");
    startTime = (float)d.get("startTime");

    // Grid fundamental w and h
    PVector dimensions = new PVector(parseWidthParam(d.get("gridW")), parseHeightParam(d.get("gridH")));
    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    fundamental = new Drawable();
    fundamental.dimensions = dimensions;
    this.shapeType = (String)d.get("gridShape");
    fundamental.drawOrbit = this.drawOrbit;
    
   this.drawables = new Drawable[numX][numY];
   
   
  //3: 1/6
  //2: 1/4
  //5: 1/10
   float offsetX = width/(numX*2);
   float offsetY = height/(numY*2);//width/numY/numY;
    if (this.shapeType.equals("rect")){      
     for(int i = 0; i < this.numX; i++){
       for(int j = 0; j < this.numY; j++){
         Rect r = new Rect(this.fundamental.dimensions);
         r.drawOrbit = this.drawOrbit;
         r.pos = new PVector((i*width/this.numX)+offsetX, height*j/this.numY+offsetY);
         r.expireTime = this.expireTime;
         r.startTime = this.startTime;
         this.drawables[i][j] = r;
       }
     }
   } else if (this.shapeType.equals("ellipse")){
   for(int i = 0; i < this.numX; i++){
       for(int j = 0; j < this.numY; j++){
         Ellipse r = new Ellipse(this.fundamental.dimensions);
         r.drawOrbit = this.drawOrbit;
         r.pos = new PVector(i*width/this.numX+r.dimensions.x/2+offsetX, height*j/this.numY+r.dimensions.y/2+offsetY);
         r.expireTime = this.expireTime;
         r.startTime = this.startTime;
         this.drawables[i][j] = r;
       }
     }
   }
  }
  
  Boolean isDefined(HashMap <String, Object> d ){
    return d.containsKey("gridNumX")&&d.containsKey("gridNumY")&&d.containsKey("gridShape")&&d.containsKey("gridW")&&d.containsKey("gridH");
  }
  
  void draw (float time){
     for(int i = 0; i < this.numX; i++){
       for(int j = 0; j < this.numY; j++){
        this.drawables[i][j].draw(time);
       }
     }
  //else if (this.shapeType.equals("ellipse")){
  //   for(int i = 1; i <= numX; i++){
  //     for(int j = 1; i <= numY; i++){
  //       Ellipse r = new Ellipse(this.fundamental.dimensions);
  //       r.drawOrbit = this.drawOrbit;
  //       r.pos.x = width*i/numX;
  //       r.pos.y = height*j/numY;
  //       r.draw(time);
  //     }
  //   }
  // }
  }
  
}



class Line extends Drawable {
  PVector end;
  int stroke;

Line(){}
  
  Line (HashMap<String,Object> d){
    pos = new PVector(parseWidthParam(d.get("lineStartX")), parseHeightParam(d.get("lineStartY")));
    end = new PVector(parseWidthParam(d.get("lineEndX")), parseHeightParam(d.get("lineEndY")));
    rotation = parseRotation((float)d.getOrDefault("lineRotation",0.0f));
    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    expireTime = (float)d.get("expireTime");
    stroke = (int)d.getOrDefault("lineStroke",1);
    startTime = (float)d.get("startTime");
  }
  
  Boolean isDefined(HashMap <String, Object> d ){
    return d.containsKey("lineStartX")&&d.containsKey("lineStartY")&&d.containsKey("lineEndX")&&d.containsKey("lineEndY")&&d.containsKey("lineStroke");
  }
  
  void draw (float time){
   
   pos.x += drawOrbit.momentum.x;
   pos.y += drawOrbit.momentum.y;
   end.x += drawOrbit.momentum.x;
   end.y += drawOrbit.momentum.y;
   pushMatrix();
   rotate(rotation+this.drawOrbit.rotation);
   setColor(time);
   strokeWeight(this.stroke);
   line(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y, this.end.x+this.drawOrbit.translation.x,this.end.y+this.drawOrbit.translation.y);
   popMatrix();
  }
}


class Ellipse extends Drawable {
  
  Ellipse () {
  }
  Ellipse (PVector d){
    this.dimensions =d;
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
    setPos();
    setColor(time);
    ellipse(0, 0, dimensions.x, dimensions.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("ellipseX")&&d.containsKey("ellipseY")&&d.containsKey("ellipseW")&&d.containsKey("ellipseH");
  }
}// end Ellipse






class Arc extends Drawable {
  public PVector trace; //start/stop in processing arc documentation

  Arc () {
  }
  
  Arc (PVector dim, PVector trace){
    this.dimensions = dim;
    this.trace = trace;
  }

  Arc (HashMap<String, Object> d) {
    
    pos = new PVector(parseWidthParam(d.get("arcX")), parseHeightParam(d.get("arcY")));
    
    dimensions = new PVector(parseWidthParam(d.get("arcW")), parseHeightParam(d.get("arcH")));
    
    trace = new PVector ((float)d.get("arcStart")*PI*2,(float)d.get("arcStop")*PI*2);

    drawOrbit = (DrawOrbit)d.get("drawOrbit");
    
    expireTime = (float)d.get("expireTime");
    startTime = (float)d.get("startTime");
    
  }

  void draw(float time) {
    pushMatrix();
    setPos();
    setColor(time);    
    arc(0, 0, dimensions.x, dimensions.y, trace.x, trace.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("arcX")&&d.containsKey("arcY")&&d.containsKey("arcW")&&d.containsKey("arcH")&&d.containsKey("arcStart")&&d.containsKey("arcStop");
  }
} // end Rect


class Rect extends Drawable {

  Rect () {
  }
  
  Rect(PVector dim){
   this.dimensions = dim; 
  }

  Rect(PVector pos, PVector dimensions, float rot) {
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
    setPos();
    setColor(time);
    rect((-1)*this.dimensions.x/2, (-1)*this.dimensions.y/2, dimensions.x, dimensions.y);
    popMatrix();
  }

  boolean isDefined(HashMap<String, Object> d) {
    return d.containsKey("rectX")&&d.containsKey("rectY")&&d.containsKey("rectW")&&d.containsKey("rectH");
  }
} // end Rect

class Drawable extends Object {
  DrawOrbit drawOrbit;
  float expireTime;
  float startTime;
  public PVector pos;
  public PVector dimensions;
  public float rotation;

  void setPos(){
    pos.x += drawOrbit.momentum.x;
    pos.y += drawOrbit.momentum.y;
    translate(pos.x+this.drawOrbit.translation.x, pos.y+this.drawOrbit.translation.y);
    rotate(rotation+this.drawOrbit.rotation);
  }
  
  void setColor(float time){
    float dur = expireTime-startTime;
    //color col = lerpColor(this.drawOrbit.c.toColor(), color(this.drawOrbit.c.r,this.drawOrbit.c.g, this.drawOrbit.c.b, 0), (time-startTime)/dur);
    color col = lerpColor(this.drawOrbit.c.toColor(), this.drawOrbit.cEnd.toColor(), (time-startTime)/dur);
    fill(col);
    stroke(col);
    //stroke(this.drawOrbit.c.toColor());
  }
  
  void draw(float time){
  }
}


class DrawOrbit {
  //public static DrawOrbit[] drawOrbits;
  Color c;
  Color cEnd;
  float rotation;
  PVector translation;
  float sustain;
  PVector momentum;
  
  DrawOrbit(Color c, Color cEnd,float rotation, PVector translation, float sustain, PVector momentum) {
    this.c = c;
    this.cEnd = cEnd;
    this.rotation = rotation;
    this.translation = translation;
    this.sustain = sustain;
    this.momentum = momentum;
  }
  
  void setOrbitParams(HashMap<String, Object> params){
    this.c.r = parseColorComponent(params.getOrDefault("colorR",this.c.r*255.0));
    this.c.g = parseColorComponent(params.getOrDefault("colorG",this.c.g*255.0));
    this.c.b = parseColorComponent(params.getOrDefault("colorB",this.c.b*255.0));
    
    this.cEnd.r = parseColorComponent(params.getOrDefault("colorEndR",this.c.r*255.0));
    this.cEnd.g = parseColorComponent(params.getOrDefault("colorEndG",this.c.g*255.0));
    this.cEnd.b = parseColorComponent(params.getOrDefault("colorEndB",this.c.b*255.0));
    this.cEnd.a = parseColorComponent(params.getOrDefault("colorEndA",0.0));
    
    this.translation.x = parseWidthTranslation(params.getOrDefault("translateX",reverseParseWidthTranslation(this.translation.x))); 
    this.translation.y = parseHeightTranslation(params.getOrDefault("translateY",reverseParseHeightTranslation(this.translation.y)));
    
    this.rotation = parseRotation(params.getOrDefault("rotate",this.rotation/PI/2));
    this.sustain = parseSustain(params.getOrDefault("drawSustain",this.sustain/1000));
    this.momentum.x = (float)params.getOrDefault("momentumX",this.momentum.x);
    this.momentum.y = (float)params.getOrDefault("momentumY",this.momentum.y);
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


//void setOrbitParams(HashMap<String, Object> params) {
//  Object[] keys = params.keySet().toArray();
//  //Color c = color(0,0,0);
//  color oc;
//  for (int i =0; i<keys.length; i++) {
//    String paramKey = keys[i].toString();
//    switch (paramKey) {
//    case "colorR0": 
//      drawOrbits[0].c.r = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorG0": 
//      drawOrbits[0].c.g = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorB0": 
      
//      drawOrbits[0].c.b = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorR1": 
//      drawOrbits[1].c.r = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorG1": 
//      drawOrbits[1].c.g = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorB1": 
//      drawOrbits[1].c.b = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorR2": 
//      drawOrbits[2].c.r = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorG2": 
//      drawOrbits[2].c.g = parseColorComponent(params.get(paramKey));
//      break;
//    case "colorB2": 
//      drawOrbits[2].c.b = parseColorComponent(params.get(paramKey));
//      break;

//    case "translateX0": 
//      drawOrbits[0].translation.x = parseWidthTranslation(params.get(paramKey));
//      break;
//    case "translateY0": 
//      drawOrbits[0].translation.y = parseHeightTranslation(params.get(paramKey));
//      break;
//    case "rotate0": 
//      drawOrbits[0].rotation = parseRotation(params.get(paramKey));
//      break;

//    case "translateX1": 
//      drawOrbits[1].translation.x = parseWidthTranslation(params.get(paramKey));
//      break;
//    case "translateY1": 
//      drawOrbits[1].translation.y = parseHeightTranslation(params.get(paramKey));
//      break;
//    case "rotate1": 
//      drawOrbits[1].rotation = parseRotation(params.get(paramKey));
//      break;

//    case "translateX2": 
//      drawOrbits[2].translation.x = parseWidthTranslation(params.get(paramKey));
//      break;
//    case "translateY2": 
//      DrawOrbit.drawOrbits[2].translation.y = parseHeightTranslation(params.get(paramKey));
//      break;
//    case "rotate2": 
//      DrawOrbit.drawOrbits[2].rotation = parseRotation(params.get(paramKey));
//      break;
      
//     case "drawSustain0":
//       DrawOrbit.drawOrbits[0].sustain = parseSustain(params.get(paramKey));
//       break;
//     case "drawSustain1":
//       DrawOrbit.drawOrbits[1].sustain = parseSustain(params.get(paramKey));
//       break;
//     case "drawSustain2":
//       DrawOrbit.drawOrbits[2].sustain = parseSustain(params.get(paramKey));
//       break;
//    }
//  }
//}

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

float reverseParseWidthTranslation( float value){
   return ((value*2)+1)/2/width;
}

float parseHeightTranslation(Object value) {
  return (height  * 2* ((float) value)-1)/2;
}

float reverseParseHeightTranslation( float value){
   return ((value*2)+1)/2/height;
}


float parseRotation (Object value){
  return PI*((float)value);
}