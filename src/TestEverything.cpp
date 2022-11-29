#include "TestEverything.h"

void TestEverything::test_everything() {
  Editor editor;
  editor.load("C:/Users/brand/Justly/examples/simple.json");
  auto &song = editor.song;
  QCOMPARE(song.rowCount(), 3);
  auto &first_chord_node = song.root.get_child(0);
  first_chord_node.note_chord_pointer -> test();
  QCOMPARE(first_chord_node.get_child_count(), 3);
  auto &first_note_node = first_chord_node.get_child(0);
  first_note_node.note_chord_pointer -> test();
  auto first_chord_index = song.index(1, 1);
  auto first_note_index = song.index(1, 1, first_chord_index);
  
  
  editor.save("C:/Users/brand/Justly/examples/simple.json");
}
