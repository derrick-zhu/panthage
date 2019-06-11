#!/usr/bin/ruby
# frozen_string_literal: true

# String extension constants or methods
class String
  def white
    String.colorize(self, 37).strip.freeze
  end

  def black
    String.colorize(self, 30).strip.freeze
  end

  def red
    String.colorize(self, 31).strip.freeze
  end

  def green
    String.colorize(self, 32).strip.freeze
  end

  def brown
    String.colorize(self, 33).strip.freeze
  end

  def blue
    String.colorize(self, 34).strip.freeze
  end

  def magenta
    String.colorize(self, 35).strip.freeze
  end

  def cyan
    String.colorize(self, 36).strip.freeze
  end

  def gray
    String.colorize(self, 37).strip.freeze
  end

  def bg_black
    String.colorize(self, 40).strip.freeze
  end

  def bg_red
    String.colorize(self, 41).strip.freeze
  end

  def bg_green
    String.colorize(self, 42).strip.freeze
  end

  def bg_brown
    String.colorize(self, 43).strip.freeze
  end

  def bg_blue
    String.colorize(self, 44).strip.freeze
  end

  def bg_magenta
    String.colorize(self, 45).strip.freeze
  end

  def bg_cyan
    String.colorize(self, 46).strip.freeze
  end

  def bg_gray
    String.colorize(self, 47).strip.freeze
  end

  def bold
    "\e[1m#{self}\e[22m".strip.freeze
  end

  def italic
    "\e[3m#{self}\e[23m".strip.freeze
  end

  def underline
    "\e[4m#{self}\e[24m".strip.freeze
  end

  def blink
    "\e[5m#{self}\e[25m".strip.freeze
  end

  def reverse_color
    "\e[7m#{self}\e[27m".strip.freeze
  end

  def self.colorize(text, color_code)
    "\e[#{color_code}m#{text}\e[0m"
  end
end
