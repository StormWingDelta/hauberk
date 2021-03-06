import 'dart:html' as html;
import 'dart:js';

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/debug.dart';
import 'package:hauberk/src/engine.dart';
import 'package:hauberk/src/ui/game_screen.dart';
import 'package:hauberk/src/ui/input.dart';
import 'package:hauberk/src/ui/main_menu_screen.dart';

const width = 80;
const height = 40;

final terminals = <TerminalView>[];
UserInterface<Input> ui;
TerminalView currentView;

final Set<Monster> _debugMonsters = Set();

class TerminalView {
  final String name;
  final html.Element element;
  final RenderableTerminal terminal;
  final int charWidth;
  final int charHeight;

  TerminalView(this.name, this.element, this.terminal,
      {this.charWidth, this.charHeight});
}

addTerminal(String name, int w, [int h]) {
  var element = html.CanvasElement();
  element.onDoubleClick.listen((_) {
    fullscreen(element);
  });

  // Make the terminal.
  var file = "font_$w";
  if (h != null) file += "_$h";
  var terminal = RetroTerminal(width, height, "$file.png",
      canvas: element, charWidth: w, charHeight: h ?? w);

  terminals.add(
      TerminalView(name, element, terminal, charWidth: w, charHeight: h ?? w));

  if (Debug.enabled) {
    // Clicking a monster toggles its debug pane.
    element.onClick.listen((event) {
      var gameScreen = Debug.gameScreen as GameScreen;
      if (gameScreen == null) return;

      var pixel = Vec(event.offset.x.toInt(), event.offset.y.toInt());
      var pos = terminal.pixelToChar(pixel);

      var absolute = pos + gameScreen.cameraBounds.topLeft;
      if (!gameScreen.cameraBounds.contains(absolute)) return;

      var actor = gameScreen.game.stage.actorAt(absolute);
      if (actor is Monster) {
        if (_debugMonsters.contains(actor)) {
          _debugMonsters.remove(actor);
        } else {
          _debugMonsters.add(actor);
        }

        _refreshDebugBoxes();
      }
    });
  }

  // Make a button for it.
  var button = html.ButtonElement();
  button.innerHtml = name;
  button.onClick.listen((_) {
    for (var i = 0; i < terminals.length; i++) {
      if (terminals[i].name == name) {
        currentView = terminals[i];
        html.querySelector("#game").append(currentView.element);
      } else {
        terminals[i].element.remove();
      }
    }
    ui.setTerminal(terminal);

    if (Debug.enabled) _refreshDebugBoxes();

    // Remember the preference.
    html.window.localStorage['font'] = name;
  });

  html.querySelector('.button-bar').children.add(button);
}

main() {
  var content = createContent();

  addTerminal("Small", 8);
  addTerminal("Large", 16);
  addTerminal("Small Rect", 8, 10);
  addTerminal("Large Rect", 16, 20);

  // Load the user's font preference, if any.
  var font = html.window.localStorage['font'];
  var fontIndex = 1;
  for (var i = 0; i < terminals.length; i++) {
    if (terminals[i].name == font) {
      fontIndex = i;
      break;
    }
  }

  currentView = terminals[fontIndex];
  html.querySelector("#game").append(currentView.element);

  ui = UserInterface<Input>(currentView.terminal);

  // Set up the keyPress.
  ui.keyPress.bind(Input.ok, KeyCode.enter);
  ui.keyPress.bind(Input.cancel, KeyCode.escape);
  ui.keyPress.bind(Input.forfeit, KeyCode.f, shift: true);
  ui.keyPress.bind(Input.quit, KeyCode.q);

  ui.keyPress.bind(Input.open, KeyCode.c, shift: true);
  ui.keyPress.bind(Input.close, KeyCode.c);
  ui.keyPress.bind(Input.drop, KeyCode.d);
  ui.keyPress.bind(Input.use, KeyCode.u);
  ui.keyPress.bind(Input.pickUp, KeyCode.g);
  ui.keyPress.bind(Input.swap, KeyCode.x);
  ui.keyPress.bind(Input.unequip, KeyCode.e);
  ui.keyPress.bind(Input.toss, KeyCode.t);
  ui.keyPress.bind(Input.selectSkill, KeyCode.s);
  ui.keyPress.bind(Input.heroInfo, KeyCode.a);
  ui.keyPress.bind(Input.editSkills, KeyCode.s, shift: true);

  // Laptop directions.
  ui.keyPress.bind(Input.nw, KeyCode.i);
  ui.keyPress.bind(Input.n, KeyCode.o);
  ui.keyPress.bind(Input.ne, KeyCode.p);
  ui.keyPress.bind(Input.w, KeyCode.k);
  ui.keyPress.bind(Input.e, KeyCode.semicolon);
  ui.keyPress.bind(Input.sw, KeyCode.comma);
  ui.keyPress.bind(Input.s, KeyCode.period);
  ui.keyPress.bind(Input.se, KeyCode.slash);
  ui.keyPress.bind(Input.runNW, KeyCode.i, shift: true);
  ui.keyPress.bind(Input.runN, KeyCode.o, shift: true);
  ui.keyPress.bind(Input.runNE, KeyCode.p, shift: true);
  ui.keyPress.bind(Input.runW, KeyCode.k, shift: true);
  ui.keyPress.bind(Input.runE, KeyCode.semicolon, shift: true);
  ui.keyPress.bind(Input.runSW, KeyCode.comma, shift: true);
  ui.keyPress.bind(Input.runS, KeyCode.period, shift: true);
  ui.keyPress.bind(Input.runSE, KeyCode.slash, shift: true);
  ui.keyPress.bind(Input.fireNW, KeyCode.i, alt: true);
  ui.keyPress.bind(Input.fireN, KeyCode.o, alt: true);
  ui.keyPress.bind(Input.fireNE, KeyCode.p, alt: true);
  ui.keyPress.bind(Input.fireW, KeyCode.k, alt: true);
  ui.keyPress.bind(Input.fireE, KeyCode.semicolon, alt: true);
  ui.keyPress.bind(Input.fireSW, KeyCode.comma, alt: true);
  ui.keyPress.bind(Input.fireS, KeyCode.period, alt: true);
  ui.keyPress.bind(Input.fireSE, KeyCode.slash, alt: true);

  ui.keyPress.bind(Input.ok, KeyCode.l);
  ui.keyPress.bind(Input.rest, KeyCode.l, shift: true);
  ui.keyPress.bind(Input.fire, KeyCode.l, alt: true);

  // Arrow keys.
  ui.keyPress.bind(Input.n, KeyCode.up);
  ui.keyPress.bind(Input.w, KeyCode.left);
  ui.keyPress.bind(Input.e, KeyCode.right);
  ui.keyPress.bind(Input.s, KeyCode.down);
  ui.keyPress.bind(Input.runN, KeyCode.up, shift: true);
  ui.keyPress.bind(Input.runW, KeyCode.left, shift: true);
  ui.keyPress.bind(Input.runE, KeyCode.right, shift: true);
  ui.keyPress.bind(Input.runS, KeyCode.down, shift: true);
  ui.keyPress.bind(Input.fireN, KeyCode.up, alt: true);
  ui.keyPress.bind(Input.fireW, KeyCode.left, alt: true);
  ui.keyPress.bind(Input.fireE, KeyCode.right, alt: true);
  ui.keyPress.bind(Input.fireS, KeyCode.down, alt: true);

  // Numeric keypad.
  ui.keyPress.bind(Input.nw, KeyCode.numpad7);
  ui.keyPress.bind(Input.n, KeyCode.numpad8);
  ui.keyPress.bind(Input.ne, KeyCode.numpad9);
  ui.keyPress.bind(Input.w, KeyCode.numpad4);
  ui.keyPress.bind(Input.e, KeyCode.numpad6);
  ui.keyPress.bind(Input.sw, KeyCode.numpad1);
  ui.keyPress.bind(Input.s, KeyCode.numpad2);
  ui.keyPress.bind(Input.se, KeyCode.numpad3);
  ui.keyPress.bind(Input.runNW, KeyCode.numpad7, shift: true);
  ui.keyPress.bind(Input.runN, KeyCode.numpad8, shift: true);
  ui.keyPress.bind(Input.runNE, KeyCode.numpad9, shift: true);
  ui.keyPress.bind(Input.runW, KeyCode.numpad4, shift: true);
  ui.keyPress.bind(Input.runE, KeyCode.numpad6, shift: true);
  ui.keyPress.bind(Input.runSW, KeyCode.numpad1, shift: true);
  ui.keyPress.bind(Input.runS, KeyCode.numpad2, shift: true);
  ui.keyPress.bind(Input.runSE, KeyCode.numpad3, shift: true);

  ui.keyPress.bind(Input.ok, KeyCode.numpad5);
  ui.keyPress.bind(Input.rest, KeyCode.numpad5, shift: true);
  ui.keyPress.bind(Input.fire, KeyCode.numpad5, alt: true);

  ui.keyPress.bind(Input.wizard, KeyCode.w, shift: true, alt: true);

  ui.push(MainMenuScreen(content));

  ui.handlingInput = true;
  ui.running = true;

  if (Debug.enabled) {
    html.document.body.onKeyDown.listen((_) {
      _refreshDebugBoxes();
    });
  }
}

/// See: https://stackoverflow.com/a/29715395/9457
void fullscreen(html.Element element) {
  var jsElement = JsObject.fromBrowserObject(element);

  if (jsElement.hasProperty("requestFullscreen")) {
    jsElement.callMethod("requestFullscreen");
  } else {
    var methods = [
      'mozRequestFullScreen',
      'webkitRequestFullscreen',
      'msRequestFullscreen'
    ];
    for (var method in methods) {
      if (jsElement.hasProperty(method)) {
        jsElement.callMethod(method);
        return;
      }
    }
  }
}

void _refreshDebugBoxes() async {
  // Hack: Give the engine a chance to update.
  await html.window.animationFrame;

  for (var debugBox in html.querySelectorAll(".debug")) {
    html.document.body.children.remove(debugBox);
  }

  var gameScreen = Debug.gameScreen as GameScreen;

  _debugMonsters.removeWhere((monster) => !monster.isAlive);
  for (var monster in _debugMonsters) {
    if (gameScreen.cameraBounds.contains(monster.pos)) {
      var screenPos = monster.pos - gameScreen.cameraBounds.topLeft;

      var info = Debug.monsterInfo(monster);
      if (info == null) continue;

      var debugBox = html.PreElement();
      debugBox.className = "debug";
      debugBox.style.display = "inline-block";

      var x = (screenPos.x + 1) * currentView.charWidth +
          currentView.element.offset.left.toInt() +
          4;
      var y = (screenPos.y) * currentView.charHeight +
          currentView.element.offset.top.toInt() +
          2;
      debugBox.style.left = x.toString();
      debugBox.style.top = y.toString();
      debugBox.text = info;

      html.document.body.children.add(debugBox);
    }
  }
}
