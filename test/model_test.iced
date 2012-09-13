{ ok, equal } = require 'assert'
R             = require '../lib/reactive'


describe 'R.Model', ->

  describe "#get()", ->

    it "should return a value set via #set()", ->
      m = new R.Model()
      m.set('foo', 42)
      equal m.get('foo'), 42

  describe "#has()", ->

    it "should return no for undefined attributes", ->
      m = new R.Model()
      equal m.has('foo'), no

    it "should return no for attributes set to undefined", ->
      m = new R.Model()
      m.set('foo', undefined)
      equal m.has('foo'), no

    it "should return no for attributes set to null", ->
      m = new R.Model()
      m.set('foo', null)
      equal m.has('foo'), no

    it "should return yes for attributes set to anything else", ->
      m = new R.Model()
      m.set('foo', '')
      equal m.has('foo'), yes

  describe "#set()", ->

    it "should emit a change event on R.Universe", (done) ->
      u = new R.Universe()
      m = new R.Model()

      await
        u.once 'change', defer(model, attr)
        m.set 'foo', 42
      equal model, m
      equal attr, 'foo'

      u.destroy()
      done()

    it "should emit the change event asynchronously", (done) ->
      u = new R.Universe()
      m = new R.Model()

      u.once 'change', ->
        ok afterSet
        done()

      m.set 'foo', 42
      afterSet = yes

    it "should emit the change event once for any number of consecutive changes", (done) ->
      u = new R.Universe()
      m = new R.Model()

      count = 0
      u.on 'change', ->
        ++count
        equal m.get('foo'), 44
      u.then ->
        equal count, 1
        equal m.get('foo'), 44
        done()

      m.set 'foo', 42
      m.set 'foo', 43
      m.set 'foo', 44
