


class Camera {
  Window w;
  
  Camera(Window wIn) {
    w = wIn;
  }
  
  void keyPressed() {
  }
  
  void keyReleased() {
  }
  
  void mouseDragged() {
    if(mouseButton == RIGHT) {
      if(!(keyPressed && keyCode == ALT)) {
        //rotate around a point about 10 units in front of yourself
        Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
        Vector3f eye = new Vector3f();
        modelViewMatrixInvert.getTranslation(eye);
        Vector3f forward = new Vector3f();
        modelViewMatrixInvert.transformDirection(0, 0, -1, forward);
        forward.mul(2.0);
        eye.add(forward);
        //Vector3f dir = new Vector3f();
        //modelViewMatrixInvert.positiveZ(dir);
        //dir.mul(-10.0);
        //eye.add(dir);        
        
        Vector3f right = new Vector3f();
        modelViewMatrixInvert.transformDirection(-1, 0, 0, right);
        Vector3f up = new Vector3f();
        modelViewMatrixInvert.transformDirection(0, -1, 0, up);
        w.modelViewMatrix.translate(eye.x, eye.y, eye.z)
          .rotate((w.selectMouseEndY - w.selectMouseStartY) * -(.31415 / 180.0) * ROTATE_SPEED * 0.2, right)
          .translate(-eye.x, -eye.y, -eye.z);
          
        /*modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
        modelViewMatrixInvert.getTranslation(eye);
        modelViewMatrixInvert.positiveZ(dir);
        dir.mul(-10.0);
        eye.add(dir);*/  
          
        w.modelViewMatrix.translate(eye.x, eye.y, eye.z)
          .rotate((w.selectMouseEndX - w.selectMouseStartX) * -(.31415 / 180.0) * ROTATE_SPEED * 0.2, up)
          .translate(-eye.x, -eye.y, -eye.z);
          
        w.selectMouseStartX = w.selectMouseEndX;
        w.selectMouseStartY = w.selectMouseEndY;
        //w.debugPoint = eye;
      } else {
        Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
        Vector3f up = new Vector3f();
        modelViewMatrixInvert.transformDirection(0, 1, 0, up);
        up.normalize(up);
        
        Vector3f right = new Vector3f();
        modelViewMatrixInvert.transformDirection(1, 0, 0, right);
        right.normalize(right);
        
        w.modelViewMatrix.rotate((w.selectMouseEndY - w.selectMouseStartY) * -(.31415 / 180.0) * ROTATE_SPEED, right);
        w.modelViewMatrix.rotate((w.selectMouseEndX - w.selectMouseStartX) * (.31415 / 180.0) * ROTATE_SPEED, up);
        w.selectMouseStartX = w.selectMouseEndX;
        w.selectMouseStartY = w.selectMouseEndY;
      }
    }
  }
  
  void update() {
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    if(keyDown['w']) { //w
      Vector3f forward = new Vector3f();
      modelViewMatrixInvert.transformDirection(0, 0, 1, forward);
      forward.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(forward);
    } 
    if(keyDown['s']) { //don't know s yet
      Vector3f backward = new Vector3f();
      modelViewMatrixInvert.transformDirection(0, 0, -1, backward);
      backward.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(backward);
    } 
    if(keyDown['a']) {
      Vector3f left = new Vector3f();
      modelViewMatrixInvert.transformDirection(1, 0, 0, left);
      left.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(left);
    } 
    if(keyDown['d']) {
      Vector3f right = new Vector3f();
      modelViewMatrixInvert.transformDirection(-1, 0, 0, right);
      right.mul(keyCodeDown[16] ? CAMERA_MOVEMENT_SHIFT_SCALE : CAMERA_MOVEMENT_SCALE);
      w.modelViewMatrix.translate(right);
    }
  }
  
  void pan(float x, float y) {
    
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    Vector3f up = new Vector3f();
    modelViewMatrixInvert.transformDirection(0, -1, 0, up);
    up.mul(y * PAN_SPEED_3D);
    w.modelViewMatrix.translate(up); 
    Vector3f right = new Vector3f();
    modelViewMatrixInvert.transformDirection(1, 0, 0, right);
    right.mul(x * PAN_SPEED_3D);
    w.modelViewMatrix.translate(right);
  }
  
  void moveForward(float amount) {
    Matrix4f modelViewMatrixInvert = new Matrix4f(w.modelViewMatrix).invert();
    Vector3f forward = new Vector3f();
    modelViewMatrixInvert.transformDirection(0, 0, -1, forward);
    forward.mul(amount);
    w.modelViewMatrix.translate(forward);
  }
  
  void frameModel() {
    ArrayList<Vertex> selected = new ArrayList<Vertex>();
    for (Vertex v: vertices) {
      if(v.selected) {
        selected.add(v);
      }
    }
    ArrayList<Face> selectedFaces = new ArrayList<Face>();
    for (Face f: faces) {
      if(f.selected) {
        selectedFaces.add(f);
      }
    }
    Vertex centerOfMass = new Vertex(0.0, 0.0, 0.0);
    Vertex min = new Vertex(MAX_FLOAT, MAX_FLOAT, MAX_FLOAT);
    Vertex max = new Vertex(-MAX_FLOAT, -MAX_FLOAT, -MAX_FLOAT);
    float scale = 1.0;
    if((selected.size() == 0) && (selectedFaces.size() == 0)) {
      for (Vertex v : vertices) {
        centerOfMass.x += v.x * (1.0 / vertices.size());
        centerOfMass.y += v.y * (1.0 / vertices.size());
        centerOfMass.z += v.z * (1.0 / vertices.size());
        min.x = min(min.x, v.x);
        min.y = min(min.y, v.y);
        min.z = min(min.z, v.z);
        max.x = max(max.x, v.x);
        max.y = max(max.y, v.y);
        max.z = max(max.z, v.z);
      }    
    } else if(selected.size() > 0) {
      for (Vertex v : selected) {
        centerOfMass.x += v.x * (1.0 / selected.size());
        centerOfMass.y += v.y * (1.0 / selected.size());
        centerOfMass.z += v.z * (1.0 / selected.size());
        min.x = min(min.x, v.x);
        min.y = min(min.y, v.y);
        min.z = min(min.z, v.z);
        max.x = max(max.x, v.x);
        max.y = max(max.y, v.y);
        max.z = max(max.z, v.z);
      }    
    } else {
      for (Face f : faces) {
        centerOfMass.x += f.v1.v.x * (0.33333333333 / faces.size());
        centerOfMass.y += f.v1.v.y * (0.33333333333 / faces.size());
        centerOfMass.z += f.v1.v.z * (0.33333333333 / faces.size());
        min.x = min(min.x, f.v1.v.x);
        min.y = min(min.y, f.v1.v.y);
        min.z = min(min.z, f.v1.v.z);
        max.x = max(max.x, f.v1.v.x);
        max.y = max(max.y, f.v1.v.y);
        max.z = max(max.z, f.v1.v.z);
        centerOfMass.x += f.v2.v.x * (0.33333333333 / faces.size());
        centerOfMass.y += f.v2.v.y * (0.33333333333 / faces.size());
        centerOfMass.z += f.v2.v.z * (0.33333333333 / faces.size());
        min.x = min(min.x, f.v2.v.x);
        min.y = min(min.y, f.v2.v.y);
        min.z = min(min.z, f.v2.v.z);
        max.x = max(max.x, f.v2.v.x);
        max.y = max(max.y, f.v2.v.y);
        max.z = max(max.z, f.v2.v.z);
        centerOfMass.x += f.v3.v.x * (0.33333333333 / faces.size());
        centerOfMass.y += f.v3.v.y * (0.33333333333 / faces.size());
        centerOfMass.z += f.v3.v.z * (0.33333333333 / faces.size());
        min.x = min(min.x, f.v3.v.x);
        min.y = min(min.y, f.v3.v.y);
        min.z = min(min.z, f.v3.v.z);
        max.x = max(max.x, f.v3.v.x);
        max.y = max(max.y, f.v3.v.y);
        max.z = max(max.z, f.v3.v.z);
      }
    }    
    scale = max((max.x - min.x), max(max.y - min.y, max.z - min.z));
    w.modelViewMatrix.setLookAt(centerOfMass.x, centerOfMass.y, centerOfMass.z + 1.2 * scale, 
      centerOfMass.x, centerOfMass.y, centerOfMass.z,
      0.0, -1.0, 0.0);
  }
}
