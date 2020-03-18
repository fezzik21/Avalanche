class Vertex {
  float x, y, z;
  boolean selected;
  
  Vertex(float inX, float inY, float inZ) {
    x = inX; y = inY; z = inZ;
    selected = false;
  }
  
}

class VertexRecord {
  Vertex v;  
  boolean hasNormal;
  boolean hasTexture;
  float nx, ny, nz;
  float tx, ty;
  
  VertexRecord(Vertex vIn) {
    v = vIn;
    hasNormal = false;
    hasTexture = false;
   
  }
  
  void setNormal(float inNx, float inNy, float inNz) {
    hasNormal = true;
    nx = inNx;
    ny = inNy;
    nz = inNz;
  }
  void setTexture(float inTx, float inTy) {
    hasTexture = true;
    tx = inTx;
    ty = inTy;
  }
}

class Face {
  VertexRecord v1, v2, v3;
  boolean selected;
  Material m;
  
  Face(Vertex inV1, Vertex inV2, Vertex inV3) {
    v1 = new VertexRecord(inV1); v2 = new VertexRecord(inV2); v3 = new VertexRecord(inV3);
    selected = false;
    m = null;
  }
  Face(VertexRecord inV1, VertexRecord inV2, VertexRecord inV3) {
    v1 = inV1; v2 = inV2; v3 = inV3;
    selected = false;
  }
  Face(VertexRecord inV1, VertexRecord inV2, VertexRecord inV3, Material mIn) {
    v1 = inV1; v2 = inV2; v3 = inV3;
    m = mIn;
    selected = false;
  }
}

class Material {
  String name;
  Vector3f Ka, Kd, Ks;
  PImage texture_diffuse;
  Material(String nameIn) {
    name = nameIn;
    Ka = new Vector3f();
    Kd = new Vector3f();
    Ks = new Vector3f();
    texture_diffuse = null;
  }
}

Vector3f faceNormal(Face f) {
  Vector3f e1 = new Vector3f(f.v2.v.x  - f.v1.v.x, f.v2.v.y - f.v1.v.y, f.v2.v.z - f.v1.v.z);
  Vector3f e2 = new Vector3f(f.v3.v.x  - f.v2.v.x, f.v3.v.y - f.v2.v.y, f.v3.v.z - f.v2.v.z);
  
  Vector3f n = new Vector3f(e1.y * e2.z - e1.z * e2.y,
                            e1.z * e2.x - e1.x * e2.z,
                            e1.x * e2.y - e1.y * e2.x);
  n.normalize();
  return n;
}

void toggleNormals() {
  for(int i = 0 ; i < faces.size(); ++i) {
    Face f = faces.get(i);
    if(f.selected) {
      if(f.v1.hasNormal) {
        f.v1.hasNormal = f.v2.hasNormal = f.v3.hasNormal = false;
      } else {
        Vector3f n = faceNormal(f);
        f.v1.setNormal(n.x, n.y, n.z);
        f.v2.setNormal(n.x, n.y, n.z);
        f.v3.setNormal(n.x, n.y, n.z);
        
      }
    }
  }  
}

void joinVerts() {
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  centerOfMass = new Vertex(0.0, 0.0, 0.0);
  for (Vertex v: vertices) {
    if(v.selected) {
      selected.add(v);
      centerOfMass.x += v.x;
      centerOfMass.y += v.y;
      centerOfMass.z += v.z;
    }
  }
  if(selected.size() == 0) {
    return;
  }
  centerOfMass.x /= selected.size();
  centerOfMass.y /= selected.size();
  centerOfMass.z /= selected.size();
  Vertex toSave = selected.get(0);
  toSave.x = centerOfMass.x; toSave.y = centerOfMass.y; toSave.z = centerOfMass.z;
  for(Face f: faces) {
    if(f.v1.v.selected) {
      f.v1.v = toSave;
    }
    if(f.v2.v.selected) {
      f.v2.v = toSave;
    }
    if(f.v3.v.selected) {
      f.v3.v = toSave;
    }
  }
  for(Vertex v : selected) {
    vertices.remove(v);
  }
  vertices.add(toSave);
  updateSelected();
}

Vertex makeVertex(float x, float y, float z) {
  Vertex result = new Vertex(x, y, z);
  vertices.add(result);
  return result;
}

void makeCube() {
  Vertex v1 = makeVertex(-1.0, -1.0, -1.0);
  Vertex v2 = makeVertex(-1.0, -1.0, 1.0);
  Vertex v3 = makeVertex(-1.0, 1.0, -1.0);
  Vertex v4 = makeVertex(-1.0, 1.0, 1.0);
  Vertex v5 = makeVertex(1.0, -1.0, -1.0);
  Vertex v6 = makeVertex(1.0, -1.0, 1.0);
  Vertex v7 = makeVertex(1.0, 1.0, -1.0);
  Vertex v8 = makeVertex(1.0, 1.0, 1.0);
  
  faces.add(new Face(v1, v2, v3));  
  faces.add(new Face(v2, v4, v3));
  faces.add(new Face(v1, v5, v6));
  faces.add(new Face(v1, v6, v2));
  faces.add(new Face(v3, v7, v8));
  faces.add(new Face(v3, v8, v4));
  faces.add(new Face(v5, v7, v6));
  faces.add(new Face(v6, v7, v8));
  faces.add(new Face(v2, v4, v6));
  faces.add(new Face(v4, v6, v8));
  faces.add(new Face(v1, v3, v5));
  faces.add(new Face(v3, v5, v7));
}

static final int NUM_AROUND = 15;
static final int NUM_UP = 50;

void makeSphere() {
  Vertex b = makeVertex(-1.0, 0.0, 0.0);
  ArrayList<Vertex> shelf = new ArrayList<Vertex>();
  for(int i = 0; i < NUM_AROUND; ++i) {
    float h = -1.0 + (2.0 / NUM_UP);
    float d = sqrt(1.0 - h * h);
    shelf.add(makeVertex(-1.0 + (2.0 / NUM_UP), d * cos(i * 2.0 * PI / NUM_AROUND), d * sin(i * 2.0 * PI / NUM_AROUND)));
    if(i != 0) {
      faces.add(new Face(b, shelf.get(i), shelf.get(i - 1)));
    }
  }
  faces.add(new Face(b, shelf.get(0), shelf.get(NUM_AROUND - 1)));
  
  ArrayList<Vertex> oldShelf = shelf;
  shelf = new ArrayList<Vertex>();
  for(int j = 0; j < NUM_UP - 2; ++j) {
    float h = -1.0 + (j + 1) * (2.0 / NUM_UP);
    float d = sqrt(1.0 - h * h);
    for(int i = 0; i < NUM_AROUND; ++i) {
        shelf.add(makeVertex(-1.0 + (j + 1) * (2.0 / NUM_UP), d * cos(i * 2.0 * PI / NUM_AROUND), d * sin(i * 2.0 * PI / NUM_AROUND)));
    }
    for(int i = 0; i < NUM_AROUND - 1; ++i) {
      faces.add(new Face(oldShelf.get(i + 1), shelf.get(i + 1), oldShelf.get(i)));
      faces.add(new Face(oldShelf.get(i), shelf.get(i + 1), shelf.get(i)));
    }
    faces.add(new Face(oldShelf.get(NUM_AROUND - 1), oldShelf.get(0), shelf.get(NUM_AROUND - 1)));
    faces.add(new Face(oldShelf.get(0), shelf.get(0), shelf.get(NUM_AROUND - 1)));    
    oldShelf = shelf;
    shelf = new ArrayList<Vertex>();
  }
  Vertex t = makeVertex(1.0, 0.0, 0.0);
  for(int i = 0; i < NUM_AROUND; ++i) {
    if(i != 0) {
      faces.add(new Face(t, oldShelf.get(i - 1), oldShelf.get(i)));
    }
  }
  faces.add(new Face(t, oldShelf.get(NUM_AROUND - 1), oldShelf.get(0)));
  
  return;  
}
