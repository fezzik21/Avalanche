
boolean splashActive = true;
PImage splashImage = null;

void drawSplash() {
  if(splashActive) {
    if(splashImage == null) {
      splashImage = loadImage("Avalanche_Header.png");
    }
    fill(255, 255, 255);
    stroke(92, 92, 92);
    rect(width / 2 - width / 4, height / 2 - height / 4, width / 2, height / 2);
    image(splashImage, width / 2 - 128, height / 2 - height / 4 + 50, 256, 80);
    
    fill(0, 0, 0);
    textSize(24);
    text("Welcome to Avalanche 3D!", width / 2 - width / 4 + 50, height / 2 - height / 4 + 200);
    
    
    text("Quick Tips:", width / 2 - width / 4 + 50, height / 2 - height / 4 + 250);
    text("- Every button has a hotkey in the upper left", width / 2 - width / 4 + 100, height / 2 - height / 4 + 280);
    text("- Hold space to pan the camera", width / 2 - width / 4 + 100, height / 2 - height / 4 + 310);
    text("- Right mouse rotates; hold alt to rotate model", width / 2 - width / 4 + 100, height / 2 - height / 4 + 340);
    
    textSize(12);
  }
}
