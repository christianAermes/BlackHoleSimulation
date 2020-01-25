// Render what a black hole would look like infront of an image
// -uses ray tracing
// -"photons" start at the plane of the observer and travel to the image plane
// -when they hit the image plane, the pixel of the observer plane where the photon originated from is colored 
//    in the color of the image pixel where the photon ended up 

// Some constants
float c = 30;      // speed of light
float G = 6;       // Gravitation constant
float dt = .025;   // time step
float Mass = 3000; // mass of the black hole
float bhx = -200;  // x-position of the black hole
float bhy = -200;  // y-position of the black hole
int pxSize = 1;    // pixelsize of the rendered image relative to pixelsize of original image. Larger values result in faster but coarser rendering


ArrayList<Photon> particles;
BlackHole m87;
PImage img;

// defines the distance between image an observer with the blackhole at the halfway mark. 
// Defined in setup as a multiple of the black hole's Schwarzschild radius
float boxSize;


void setup() {
  size(600, 600);
  img = loadImage("Background.jpg");
  
  // initiate black hole object
  m87 = new BlackHole(bhx, bhy, 0, Mass);
  boxSize = 10*m87.rs;
  
  // fill array list with photons for raytracing
  particles = new ArrayList<Photon>();
  for (int x=0; x< width; x+=pxSize) {
    for (int y=0; y<height; y+=pxSize) {
      particles.add(new Photon(x-width/2,y-height/2, 1000, boxSize));
    }
  }
}

void draw() {
  background(0);
  for (Photon p : particles) {
    m87.pull(p); 
    p.update();
  }
  
}

class BlackHole {
  PVector pos;
  float mass;
  float rs;

  BlackHole(float x, float y, float z, float m) {
    pos = new PVector(x, y, z);
    mass = m;
    
    // Schwarzschild radius of the black hole
    rs = (2*G*mass) / (c*c);
    println("Rs = ", rs);
  }

  void pull(Photon p) {
    // calculate relativistic gravitational pull on the photon and deflect the photon accordingly 
    PVector force = new PVector(pos.x - p.pos.x, pos.y - p.pos.y, pos.z - p.pos.z);
    float r = force.mag();
    float fg = G * mass / (r * r);

    force.setMag(c).mult(fg * (dt / c)).mult(1/abs(1.0 - 2.0 * G * mass / (r * c * c)));
    p.vel.add(force).setMag(c);
  
    // if photon is too close to the event horizon, stop the photon movement
    if (r <= rs + 0.5) {
      p.stopped = true;
    }
  }
}


class Photon {
  PVector pos, pos0;
  PVector vel;
  boolean stopped = false;
  float stopD; // z-position at which the photon should stop. Equivalent to the distance from the black hole at which the observer is placed 
  
  Photon(float x, float y, float z, float _stopD) {
    pos = new PVector(x, y, z);
    pos0 = pos.copy();
    vel = new PVector(0, 0, -c);
    stopD = _stopD;
  }

  
  void update() {
    if (!stopped) {
      //Move forward dt (delta time-step)
      PVector deltaV = vel.copy();
      deltaV.mult(dt);
      pos.add(deltaV);
    } 
    if (stopped && pos.z<=-stopD) {
      int x = int(pos.x)+img.width/2;
      int y = int(pos.y)+img.height/2;
      
      // get the index of the respective pixel from x and y position
      int idx = x+y*img.width;
      img.loadPixels();
      
      if (idx < img.pixels.length && idx >= 0) {
        color col = img.pixels[idx];
        noStroke();
        fill(col);
        
        // fill the pixel where the photon originated from with the color of the image where the photon landed
        rect(pos0.x+width/2, pos0.y+height/2, 2*pxSize, 2*pxSize);
      }
    }
    
    if (pos.z <= -stopD) {
      stopped = true;
    }
  }
}
