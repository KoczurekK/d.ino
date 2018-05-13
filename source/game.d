module game;

import player;
import cactus;
import ground;

import dsfml.graphics;
import dsfml.window;
import dsfml.system;
import dsfml.audio;

import std.random;
import std.datetime;
import std.datetime.stopwatch : StopWatch;

private Event[] events(RenderWindow window) {
  Event[] res;
  for(Event ev; window.pollEvent(ev);) {
    res ~= ev;
  }

  return res;
}

private SoundBuffer bufFromFile(string path) {
  auto res = new SoundBuffer;
  res.loadFromFile(path);
  return res;
}

private static SoundBuffer[string] buffers;
static this() {
  buffers["button"] = bufFromFile("assets/sound_button.mp3");
}

/++
 + Dino game,
 +
 + Creates a properly sized window and runs the whole simulation
 +/
class Game {
  private RenderWindow window;
  private Player player;
  private Ground ground;
  private Cactus[] cactuss;
  private float seconds_to_next_cactus = 0;
  private StopWatch cactus_stopwatch;

  private Sound button_sound;

  /++ Width/height ratio +/
  static immutable float width_to_height_ratio = 4;

  private void cactus_generation() {
    if(cactus_stopwatch.peek.asSeconds * player.speed / 300 > seconds_to_next_cactus) {
      cactuss ~= random_cactus_at(600, window.getSize.y);
      seconds_to_next_cactus = uniform01!float * 2 + 1;
      cactus_stopwatch.reset();
    }
  }

  private void on_key_pressed(Keyboard.Key code) {
    if(code == Keyboard.Key.Space || code == Keyboard.Key.Up) {
      const jumped = player.jump();
      if(jumped && button_sound.status != Sound.Status.Playing) {
        button_sound.play();
      }
    }
    if(code == Keyboard.Key.Down && player.vert_velocity > 0) {
      player.vert_velocity = 0;
    }
  }

  /++ Creates Dino game instance, size refers to height of the window +/
  this(uint size) {
    window = new RenderWindow(VideoMode(cast(uint) width_to_height_ratio * size, size), "dino");
    window.setVerticalSyncEnabled(true);

    player = new Player();
    player.window_height = size;

    cactus_stopwatch.start();

    ground = new Ground();

    button_sound = new Sound;
    button_sound.setBuffer(buffers["button"]);
  }

  /++ Runs the game +/
  void run() {
    while(window.isOpen) {
      window.clear(Color(247, 247, 247));

      foreach(ev; window.events)
      switch(ev.type) {
        case Event.EventType.Closed:     window.close();              break;
        case Event.EventType.KeyPressed: on_key_pressed(ev.key.code); break;
        default: break;
      }

      ground.move(player.displacement);
      window.draw(ground);

      player.update();
      window.draw(player);

      cactus_generation();
      foreach(ref cactus; cactuss) {
        if(player.collider.intersects(cactus.collider)) {
          window.close;
        }

        cactus.move(player.displacement);
        window.draw(cactus);
      }

      window.display();
    }
  }
}
