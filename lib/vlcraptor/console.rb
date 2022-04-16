# frozen_string_literal: true

module Vlcraptor
  class Console
    LENGTH = 120

    def initialize
      @first = true
    end

    def change(line)
      print "\b" * LENGTH unless @first
      @first = false
      print line[0...LENGTH].ljust LENGTH
    end

    def replace(line)
      print "\b" * LENGTH unless @first
      @first = true
      puts line
    end
  end
end
