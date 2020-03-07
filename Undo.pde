Stack<UndoRecord> undoRecords = new Stack<UndoRecord>();

void undo() {
  if(!undoRecords.empty()) {
    undoRecords.pop().undo();
  }
}

class UndoRecord {
  UndoRecord() {
    undoRecords.push(this);
  }
  
  void undo() {
  }
}

class UndoRecordDeletion extends UndoRecord {
  ArrayList<Face> deletedFaces;
  ArrayList<Vertex> deletedVertices;
  
  UndoRecordDeletion() {
    super();
    deletedFaces = new ArrayList<Face>();  
    deletedVertices = new ArrayList<Vertex>();
  }
  
  void addFace(Face f) {
    deletedFaces.add(f);
  }
  
  void addVertex(Vertex v) {
    deletedVertices.add(v);
  }
  
  void undo() {
    for(int i = 0; i < deletedVertices.size(); ++i) {
      vertices.add(deletedVertices.get(i));      
    }
    for(int i = 0; i < deletedFaces.size(); ++i) {
      faces.add(deletedFaces.get(i));      
    }
  }
}

class UndoFaceAddition extends UndoRecord {
  Face addedFace;
  
  UndoFaceAddition(Face f) {
    super();
    addedFace = f;
  }
  
  void undo() {
    faces.remove(addedFace);
  }
}

class UndoVertexAddition extends UndoRecord {
  Vertex addedVertex;
  
  UndoVertexAddition(Vertex v) {
    super();
    addedVertex = v;
  }
  
  void undo() {
    vertices.remove(addedVertex);
  }
}
