import java.util.*;
import java.util.prefs.Preferences;
import org.joml.*;

ArrayList<Vertex> vertices;
ArrayList<Face> faces;
ArrayList<Window> windows;
HashMap<String, Material> materials;
Button snapToGridCheckbox;
Button showVerticesCheckbox;
Button centerOfMassCheckbox;
Button darkModeCheckbox;
Vertex centerOfMass;
Vertex singleSelectedVertex;
Face singleSelectedFace;
Button showEdgesCheckbox, showFacesCheckbox, showLightingCheckbox, showNormalsCheckbox, showTexturesCheckbox, selectBackFacingCheckbox, fullScreenCheckbox;
UIImage materialDiffuseImage;
UIGroup vertexEditGroup, multipleVertexEditGroup, faceEditGroup, materialEditGroup, newMaterialGroup;
VectorEditor vEditor;
VectorEditor n1Editor, n2Editor, n3Editor;
VectorEditor t1Editor, t2Editor, t3Editor;
VectorEditor kaEditor, kdEditor, ksEditor;
TextBox commandBox;
Label editLabel;
DropDownList materialSelector;
int mode;
boolean saveNextDraw;
float oldWidth, oldHeight;
boolean ctrlPressed = false;

//This is here to keep the UI from reporting press, drag, release, click - we don't want the click at the end
boolean dragWithoutPressInvalidatesClick = false;

boolean keyDown[];
boolean lastKeyDown[];
boolean keyCodeDown[];
boolean lastKeyCodeDown[];
  
Preferences prefs;

void resetMaterials() {
  ArrayList<String> materialNames = new ArrayList<String>();
  Iterator<Material> v = materials.values().iterator();
  while(v.hasNext()) {
    Material vm = v.next();
    materialNames.add(vm.name);
  }
  materialSelector.options = materialNames;
  materialSelector.selectedOption = 0;
}

void clearSelected() {
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    v.selected = false;
  }
  for (int i = faces.size()-1; i >= 0; i--) {
    Face f = faces.get(i);
    f.selected = false;
  }
}

void updateSelected() {
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  centerOfMass = new Vertex(0.0, 0.0, 0.0);
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    if(v.selected) {
      selected.add(v);
      centerOfMass.x += v.x;
      centerOfMass.y += v.y;
      centerOfMass.z += v.z;
      vEditor.updateText(new Vector3f(v.x, v.y, v.z));
    }
  }
  ArrayList<Face> selectedFaces = new ArrayList<Face>();
  for (int i = faces.size() - 1; i >= 0; i--) {
    Face f = faces.get(i);
    if(f.selected) {
      selectedFaces.add(f);
      n1Editor.updateText(new Vector3f(f.v1.nx, f.v1.ny, f.v1.nz));
      n2Editor.updateText(new Vector3f(f.v2.nx, f.v2.ny, f.v2.nz));
      n3Editor.updateText(new Vector3f(f.v3.nx, f.v3.ny, f.v3.nz));
      t1Editor.updateText(new Vector3f(f.v1.tx, f.v1.ty, 0.0));
      t2Editor.updateText(new Vector3f(f.v2.tx, f.v2.ty, 0.0));
      t3Editor.updateText(new Vector3f(f.v3.tx, f.v3.ty, 0.0));
      if(f.m != null) {
        kaEditor.updateText(f.m.Ka);
        kdEditor.updateText(f.m.Kd);
        ksEditor.updateText(f.m.Ks);
        materialDiffuseImage.image = f.m.texture_diffuse;
      }
    }
  }
  centerOfMass.x /= selected.size();
  centerOfMass.y /= selected.size();
  centerOfMass.z /= selected.size();
  multipleVertexEditGroup.setVisible(false);
  vertexEditGroup.setVisible(false);
  faceEditGroup.setVisible(false);
  materialEditGroup.setVisible(false);
  newMaterialGroup.setVisible(false);
  if(selected.size() == 1) {
    singleSelectedVertex = selected.get(0);
    vertexEditGroup.setVisible(true);
  }
  if(selected.size() > 0) {
    multipleVertexEditGroup.setVisible(true);
  }
  boolean allSelectedFacesHaveNoMaterial = true;
  boolean allSelectedFacesHaveSameMaterial = true;
  Material jointMaterial = null;
  if(selectedFaces.size() == 0) {
    allSelectedFacesHaveNoMaterial = false;
    allSelectedFacesHaveSameMaterial = false;
  } else {
    singleSelectedFace = selectedFaces.get(0);
    for(Face f: selectedFaces) {
      if(f.m != null) {
        allSelectedFacesHaveNoMaterial = false;
        if(jointMaterial == null) {
          jointMaterial = f.m;
        } else if (jointMaterial != f.m) {
          allSelectedFacesHaveSameMaterial = false;
        }
      } else {
        allSelectedFacesHaveSameMaterial = false;
      }
    }
  }
  if(allSelectedFacesHaveNoMaterial) {
    newMaterialGroup.setVisible(true);
  } else if(allSelectedFacesHaveSameMaterial) {
    if(singleSelectedFace.m != null) {
      materialEditGroup.setVisible(true);
      materialSelector.selectedOption = materialSelector.options.indexOf(singleSelectedFace.m.name);
    }
  }
  if(selectedFaces.size() == 1) {
    if(singleSelectedFace.v1.hasNormal) {
      n1Editor.setVisible(true);
      n2Editor.setVisible(true);
      n3Editor.setVisible(true);
    }
    if(singleSelectedFace.v1.hasTexture) {
      t1Editor.setVisible(true);
      t2Editor.setVisible(true);
      t3Editor.setVisible(true);
    }
  }
}

void updateSelectedVertexPosition() {
  Vertex v = singleSelectedVertex;
  if(v.selected) {
    Vector3f vec = new Vector3f();
    vEditor.updateValues(vec);
    v.x = vec.x; v.y = vec.y; v.z = vec.z;
  }
}

void updateMaterialChoice() {
  for(Face f: faces) {
    if(f.selected) {
      f.m = materials.get(materialSelector.options.get(materialSelector.selectedOption));
    }
  }
}

void updateSelectedMaterial() {
  Face f = singleSelectedFace;
  if(f.selected) {
    Material m = f.m;
    if(m != null) {
      kaEditor.updateValues(singleSelectedFace.m.Ka);
      kdEditor.updateValues(singleSelectedFace.m.Kd);
      ksEditor.updateValues(singleSelectedFace.m.Ks);
    }
  }
}
    
void updateSelectedFace() {
  Face f = singleSelectedFace;
  if(f.selected) {
    Vector3f vec = new Vector3f();
    n1Editor.updateValues(vec);
    f.v1.nx = vec.x; f.v1.ny = vec.y; f.v1.nz = vec.z;
    n2Editor.updateValues(vec);
    f.v2.nx = vec.x; f.v2.ny = vec.y; f.v2.nz = vec.z;
    n3Editor.updateValues(vec);
    f.v3.nx = vec.x; f.v3.ny = vec.y; f.v3.nz = vec.z;
    t1Editor.updateValues(vec);
    f.v1.tx = vec.x; f.v1.ty = vec.y;
    t2Editor.updateValues(vec);
    f.v2.tx = vec.x; f.v2.ty = vec.y;
    t3Editor.updateValues(vec);
    f.v3.tx = vec.x; f.v3.ty = vec.y;
      
  }
}
void pre() {
  if((oldWidth != width) || (oldHeight != height)) {
    resizeUI(oldWidth, oldHeight, width, height);
      
    int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
    int windowHeight = height / 2 - 5;
    windows.get(0).resize(0, 0, windowWidth, windowHeight);
    windows.get(1).resize(windowWidth + 5, 0, windowWidth, windowHeight);
    windows.get(2).resize(0, windowHeight + 5, windowWidth, windowHeight);
    windows.get(3).resize(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight);    
       
    oldWidth = width;
    oldHeight = height;
  }
}

void settings() {
  if((displayWidth > 1920) && (displayHeight > 1080)) {
    size(1920, 1080, P3D);
    oldWidth = 1920;
    oldHeight = 1080;
  } else {
    size(1280, 1024, P3D);
    oldWidth = 1280;
    oldHeight = 1024;
  }
  //pixelDensity(displayDensity());
  
  PJOGL.setIcon("Avalanche_Icon.png");
}  

void toggleFullScreen() {
  if(!fullScreenCheckbox.selected) { //transition to full 3D      
    int windowWidth = (width - UI_COLUMN_WIDTH) - 5;
    int windowHeight = height - 5;
    for(Window w : windows) {
      if(w.viewType == VIEW_3D) {
        w.resize(0, 0, windowWidth, windowHeight);
      } else {
        w.resize(0, 0, 0, 0);
      }
    }
  } else { //transition away
  int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
    int windowHeight = height / 2 - 5;
    windows.get(0).resize(0, 0, windowWidth, windowHeight);
    windows.get(1).resize(windowWidth + 5, 0, windowWidth, windowHeight);
    windows.get(2).resize(0, windowHeight + 5, windowWidth, windowHeight);
    windows.get(3).resize(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight);           
  }
}

void addMaterial() {
  //Use the first material
  for(Face f: faces) {
    if(f.selected) {
      if(materials.size() == 0) {
        f.m = new Material("Avalanche1");
        materials.put(f.m.name, f.m);
        resetMaterials();
      } else { 
        Iterator<Material> v = materials.values().iterator();
        f.m = v.next();    
      }
      Vector3f n = faceNormal(f);
      f.v1.setNormal(n.x, n.y, n.z);
      f.v2.setNormal(n.x, n.y, n.z);
      f.v3.setNormal(n.x, n.y, n.z);
      f.v1.setTexture(0.0, 0.0);
      f.v2.setTexture(0.0, 1.0);
      f.v3.setTexture(1.0, 0.0);
    }
  }
  updateSelected();
}

void setup() {
  prefs = Preferences.userRoot().node(this.getClass().getName());
  if(prefs.getBoolean("SplashSeen", false)) {
    splashActive = false;
  }
  surface.setTitle("Avalanche 3D Editor");  
  frameRate(30);
  surface.setResizable(true);
  
  registerMethod ("pre", this ) ;
  
  vertices = new ArrayList<Vertex>();
  faces = new ArrayList<Face>();
  windows = new ArrayList<Window>();
  materials = new HashMap<String, Material>();
  
  keyDown = new boolean[1024];
  keyCodeDown = new boolean[1024];
  lastKeyDown = new boolean[1024];
  lastKeyCodeDown = new boolean[1024];
  
  int uiY = 10; //Starting value
  
  final PApplet myThis = this;
  
  new Button("Open", "o", false, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { openFile(myThis); } }, null );
  new Button("Save", "p", false, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { saveFile(myThis); } }, null );
  uiY += UI_BUTTON_HEIGHT;
  uiY += UI_BUTTON_BETWEEN;
  new Line(uiY, null);
  uiY += UI_BUTTON_BETWEEN;
  new Button("Place", "1", false, "Mode",  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { mode = MODE_PLACE; } }, null );
  new Button("Select Vertex", "2", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { clearSelected(); mode = MODE_SELECT_VERTEX; } }, null ).selected = true;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Button("Select Face", "3", false, "Mode",  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { clearSelected(); mode = MODE_SELECT_FACE; } }, null );
  new Button("Move", "4", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { mode = MODE_MOVE; } }, null );
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Button("Scale (All)", "5", false, "Mode",  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { mode = MODE_SCALE_ALL; } }, null );
  new Button("Scale", "6", false, "Mode",  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { mode = MODE_SCALE; } }, null );
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Button("Rotate", "7", false, "Mode",  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { mode = MODE_ROTATE; } }, null );
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Line(uiY, null);
  uiY += UI_BUTTON_BETWEEN;  
  snapToGridCheckbox = new Button("Snap To Grid", "g", true, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  centerOfMassCheckbox = new Button("Center of Mass", "h", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  centerOfMassCheckbox.selected = true;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  darkModeCheckbox = new Button("Dark Mode", "i", true, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  darkModeCheckbox.selected = true;
  selectBackFacingCheckbox = new Button("Back Facing", "o", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  selectBackFacingCheckbox.selected = true;  
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  fullScreenCheckbox = new Button("3D Only", "=", true, null, width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { toggleFullScreen(); } }, null );
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  
  new Line(uiY, null);
  uiY += UI_BUTTON_BETWEEN;  
  new Label("SHOW", uiY, null);
  uiY += UI_BUTTON_TEXT;  
  
  showVerticesCheckbox = new Button("Vertices", "z", true, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showVerticesCheckbox.selected = true;
  showEdgesCheckbox = new Button("Edges", "x", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showEdgesCheckbox.selected = true;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  showFacesCheckbox = new Button("Faces", "c", true, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showFacesCheckbox.selected = true;
  showLightingCheckbox = new Button("Light", "v", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showLightingCheckbox.selected = true;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  showNormalsCheckbox = new Button("Normals", "b", true, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showNormalsCheckbox.selected = true;
  showTexturesCheckbox = new Button("Texture", "n", true, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { } }, null );
  showTexturesCheckbox.selected = true;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Line(uiY, null);
  uiY += UI_BUTTON_BETWEEN;  
  
  new Button("Face", "f", false, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  addFace(); } }, null );
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Button("Cube", "/", false, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  makeCube(); } }, null );
  new Button("Sphere", ".", false, null,  width - UI_COLUMN_WIDTH + 10 + 110, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  makeSphere(); } }, null );  
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Button("Toggle Normal", "\\", false, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  toggleNormals(); } }, null ); 
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN;
  new Line(uiY, null);
  uiY += UI_BUTTON_BETWEEN;  
  editLabel = new Label("EDIT", uiY, null);
  uiY += UI_BUTTON_TEXT + UI_BUTTON_TEXT; 
  
  int headOfGroupY =  uiY;
  vertexEditGroup = new UIGroup();
  multipleVertexEditGroup = new UIGroup();
  new Button("Join Verts", "j", false, null,  width - UI_COLUMN_WIDTH + 10, uiY, 100, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  joinVerts(); } }, multipleVertexEditGroup ); 
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_BETWEEN + UI_BUTTON_BETWEEN;  
  vEditor = new VectorEditor("X", "Y", "Z", true, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedVertexPosition(); } }, vertexEditGroup);
  
  faceEditGroup = new UIGroup();
  n1Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  n2Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  n3Editor = new VectorEditor("NX", "NY", "NZ", true, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  t1Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  t2Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  t3Editor = new VectorEditor("U", "V", "", false, false, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedFace(); } }, faceEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  
  materialEditGroup = new UIGroup(); 
  new Line(uiY, materialEditGroup);
  uiY += UI_BUTTON_BETWEEN;  
  new Label("MATERIAL", uiY, materialEditGroup);
  uiY += UI_BUTTON_TEXT + UI_BUTTON_TEXT; 
  int savedUIY = uiY;
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  kaEditor = new VectorEditor("AR", "AG", "AB", true, true, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  kdEditor = new VectorEditor("DR", "DG", "DB", true, true, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  ksEditor = new VectorEditor("SR", "SG", "SB", true, true, width - UI_COLUMN_WIDTH + 10, uiY, new Thunk() { @Override public void apply() { updateSelectedMaterial(); } }, materialEditGroup);
  uiY += UI_BUTTON_HEIGHT + UI_BUTTON_TEXT;
  ArrayList<String> materialNames = new ArrayList<String>();
  materialSelector = new DropDownList(materialNames, width - UI_COLUMN_WIDTH + 10, savedUIY, UI_COLUMN_WIDTH - 40, 25, new Thunk() { @Override public void apply() { updateMaterialChoice(); } }, materialEditGroup);
  
  materialDiffuseImage = new UIImage(width - UI_COLUMN_WIDTH + 10, uiY, 30, 30, materialEditGroup);
  
  newMaterialGroup = new UIGroup();
  new Button("Apply A Material", "m", false, null,  width - UI_COLUMN_WIDTH + 10, headOfGroupY, 210, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() {  addMaterial(); } }, newMaterialGroup );
  newMaterialGroup.setVisible(false);
  
  commandBox = new TextBox("", "COMMAND", width - UI_COLUMN_WIDTH + 10, height - 27, UI_COLUMN_WIDTH- 20, UI_BUTTON_HEIGHT, new Thunk() { @Override public void apply() { executeCommand(); } }, null );
  commandBox.anchorBottom = true;
  
  int windowWidth = (width - UI_COLUMN_WIDTH) / 2 - 5;
  int windowHeight = height / 2 - 5;
  windows.add(new Window(0, 0, windowWidth, windowHeight, VIEW_Z));
  windows.add(new Window(windowWidth + 5, 0, windowWidth, windowHeight, VIEW_X));
  windows.add(new Window(0, windowHeight + 5, windowWidth, windowHeight, VIEW_Y));
  windows.add(new Window(windowWidth + 5, windowHeight + 5, windowWidth, windowHeight, VIEW_3D));
  
  updateSelected();
  mode = MODE_SELECT_VERTEX; 
  registerCommands();
  thread("updateUI");
  textSize(12);
  
}

void mouseWheel(MouseEvent event) {
  uiMouseWheel(event);
  for(Window w : windows) {
    w.mouseWheel(event);
  }
}

void mouseClicked() {
  if(splashActive) {
    prefs.putBoolean("SplashSeen", true);
    splashActive = false;
    return;
  }
  if(!uiTakesMouseInput()) {
    if(dragWithoutPressInvalidatesClick) {
      //we got a drag, no intervening press, then a click.  we don't want this click in our UI.
      dragWithoutPressInvalidatesClick = false;
      if(mode != MODE_PLACE) {
        return;
      }
    }
    for(Window w : windows) {
      w.mouseClicked();
    }
  }
}

void mousePressed() {
  if(!uiTakesMouseInput()) {
    dragWithoutPressInvalidatesClick = false;
    for(Window w : windows) {
      w.mousePressed();
    }
  }
}

void mouseDragged() {
  if(!uiTakesMouseInput()) {  
    dragWithoutPressInvalidatesClick = true;
    for(Window w : windows) {
      w.mouseDragged();
    }
  }
}

void mouseReleased() {   
  if(!uiTakesMouseInput()) {
    for(Window w : windows) {
      w.mouseReleased();
    }
  }
}

void keyPressed() {
  if(key < 1024) {
    lastKeyDown[key] = keyDown[key];
    keyDown[key] = true;
  }
  lastKeyCodeDown[keyCode] = keyCodeDown[keyCode];
  keyCodeDown[keyCode] = true;
  if(!uiTakesKeyInput()) {
    for(Window w : windows) {
      w.keyPressed();
    }
  }
  if(key == ESC) key = 0;
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = true;
    }
  }
}

void keyReleased() {   
    if(key < 1024) {
      lastKeyDown[key] = keyDown[key];
      keyDown[key] = false;
    }
    lastKeyCodeDown[keyCode] = keyCodeDown[keyCode];
    keyCodeDown[keyCode] = false;
    for(Window w : windows) {
    w.keyReleased();
  }
  if (key == CODED) {
    if (keyCode == CONTROL) {
      ctrlPressed = false;
    }
  }
  if(ctrlPressed && keyCode == 90) {
    undo();
  }
  if(ctrlPressed && keyCode == 65) {
    if(mode == MODE_SELECT_FACE) {
      for (int i = faces.size()-1; i >= 0; i--) {
        Face f = faces.get(i);
        f.selected = true;
      }
    } else {
      for (int i = vertices.size()-1; i >= 0; i--) {
        Vertex v = vertices.get(i);
        v.selected = true;
      }
    }
  }
  if (key == DELETE) {
    UndoRecordDeletion urd = new UndoRecordDeletion();
    for (int i = faces.size()-1; i >= 0; i--) {
      Face f = faces.get(i);
      if(f.selected || f.v1.v.selected || f.v2.v.selected || f.v3.v.selected) {
        f.selected = false;
        urd.addFace(f);
        faces.remove(f);
      }
    }
    for (int i = vertices.size()-1; i >= 0; i--) {
      Vertex v = vertices.get(i);
      if(v.selected) {
        v.selected = false;
        urd.addVertex(v);
        vertices.remove(v);
      }
    }
  } 
} 

void addFace() {  
  ArrayList<Vertex> selected = new ArrayList<Vertex>();
  for (int i = vertices.size()-1; i >= 0; i--) {
    Vertex v = vertices.get(i);
    if(v.selected) {
      selected.add(v);
    }
  }
  if(selected.size() == 3) {
    //See if the face already exists
    for (int i = faces.size()-1; i >= 0; i--) {
      Face f = faces.get(i);
      if(selected.contains(f.v1.v) && selected.contains(f.v2.v) && selected.contains(f.v3.v)) {
        new UndoRecordDeletion().addFace(f);
        faces.remove(f);
        return;
      }
    }
    Face newFace = new Face(selected.get(0), selected.get(1), selected.get(2));
    new UndoFaceAddition(newFace);
    faces.add(newFace);
  }
}

void draw() {
  background(darkModeCheckbox.selected ? 0 : 192);
  ortho(-width/2, width/2, -height/2, height/2);
  
  for(Window w : windows) {
    w.draw();
    
    fill(255, 0, 0);
    text(VIEW_NAMES[w.viewType], w.x, w.y + w.h - 10);
  }
  ortho(-width/2, width/2, -height/2, height/2);
  strokeWeight(2);
  if(darkModeCheckbox.selected) {
    stroke(192, 192, 255);
  } else {
    stroke(64, 64, 128);
  }
  if(!fullScreenCheckbox.selected) {
    line(0, height / 2, width - UI_COLUMN_WIDTH, height / 2);
    line((width - UI_COLUMN_WIDTH) / 2, 0, (width - UI_COLUMN_WIDTH) / 2, height);
  }
  
  drawUI();
  drawSplash();
  //saveFrame("test-######.tif");
}
