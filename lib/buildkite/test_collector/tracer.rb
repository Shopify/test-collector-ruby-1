# frozen_string_literal: true

module Buildkite::TestCollector
  # Traces the execution of an application by creating and storing spans of information.
  #
  # This class contains two data structures:
  #
  # - A stack (called @stack) that traces the entering & leaving of each part of the application.
  # - A tree made up of many Span nodes. Each Span is a node in the tree. Each
  #   span is also stored in the stack. The root of the tree is called @top and
  #   is stored at @stack[0].
  #
  # When the trace is complete the stack MUST contain a single node @top, which
  # is the root of the tree (see #finalize). The tree is converted into a hash
  # in #as_json which recursively calls #as_json on all of it's children.
  class Tracer
    # https://github.com/buildkite/test-collector-ruby/issues/131
    class MonotonicTime
      GET_TIME = Process.method(:clock_gettime)
      private_constant :GET_TIME

      def self.call
        GET_TIME.call Process::CLOCK_MONOTONIC
      end
    end

    class Span
      attr_accessor :section, :start_at, :end_at, :detail, :children

      def initialize(section, start_at, end_at, detail)
        @section = section
        @start_at = start_at
        @end_at = end_at
        @detail = detail
        @children = []
      end

      def as_hash
        {
          section: section,
          start_at: start_at,
          end_at: end_at,
          duration: end_at - start_at,
          detail: detail,
          children: children.map(&:as_hash),
        }.with_indifferent_access
      end
    end

    def initialize
      @top = Span.new(:top, MonotonicTime.call, nil, {})
      @stack = [@top]
    end

    def enter(section, **detail)
      new_entry = Span.new(section, MonotonicTime.call, nil, detail)
      current_span.children << new_entry
      @stack << new_entry
    end

    def leave
      current_span.end_at = MonotonicTime.call
      @stack.pop
    end

    def backfill(section, duration, **detail)
      new_entry = Span.new(section, MonotonicTime.call - duration, MonotonicTime.call, detail)
      current_span.children << new_entry
    end

    def current_span
      @stack.last
    end

    def finalize
      raise "Stack not empty" unless @stack.size == 1
      @top.end_at = MonotonicTime.call
      self
    end

    def history
      @top.as_hash
    end
  end
end
