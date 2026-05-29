module FizzBuzz
  class << self
    def call(range)
      range.each do |n|
        case 0
        when n % 15
          puts("FizzBuzz")
        when n % 3
          puts("Fizz")
        when n % 5
          puts("Buzz")
        else
          puts(n)

FizzBuzz.(1 .. 16)
