/*
 * webhook-redactor
 *
 *
 * Copyright (c) 2014 Webhook
 * Licensed under the MIT license.
 */

(function ($) {
  "use strict";

  // namespacing
  var Fixedtoolbar = function (redactor) {
    this.redactor = redactor;
    this.$window = $('.view > form'); //$(window);
    this.viewHeaderHeight = 40;

    this.$window.on('scroll', $.proxy(this.checkOffset, this));
    redactor.$box.on('scroll', $.proxy(this.checkOffset, this));

    this.redactor.$editor.on('focus', $.proxy(function () {
      this.isFocused = true;
    }, this));

    this.redactor.$editor.on('blur', $.proxy(function () {
      this.isFocused = false;
    }, this));
  };
  Fixedtoolbar.prototype = {
    isFixed: false,
    isFocused: false,

    checkOffset: function () {
      var boxOffset = this.redactor.$box.offset();

      var isBelowBoxTop = boxOffset.top - this.viewHeaderHeight <= 0;
      //var isAboveBoxBottom = boxOffset.top + this.redactor.$box.outerHeight() - this.redactor.$toolbar.outerHeight() - this.$window.scrollTop() >= 0;
      var isAboveBoxBottom = this.redactor.$box.outerHeight() + boxOffset.top - this.viewHeaderHeight - this.redactor.$toolbar.outerHeight() >= 0;

      if (isBelowBoxTop && isAboveBoxBottom) {
        this.fix();
      } else {
        this.unfix();
      }
    },

    fix: function () {

      if (this.isFixed) {

        // webkit does not recalc top: 0 when focused on contenteditable
        if (this.redactor.utils.isMobile() && this.isFocused) {
          this.redactor.$toolbar.css({
            position: 'absolute',
            top     : this.$window.scrollTop() - this.redactor.$box.offset().top,
            left    : this.redactor.$box.offset().left
          });
        }

        return;
      }

      var border_left = parseInt(this.redactor.$box.css('border-left-width').replace('px', ''), 10);

      this.redactor.$toolbar.css({
        position: 'fixed',
        top     : this.viewHeaderHeight,
        left    : this.redactor.$box.offset().left + border_left,
        width   : this.redactor.$box.width(),
        zIndex  : 300
      });

      this.redactor.$editor.css('padding-top', this.redactor.$toolbar.height() + 10);

      this.isFixed = true;

    },

    unfix: function () {
      if (!this.isFixed) {
        return;
      }

      this.redactor.$toolbar.css({
        position: 'relative',
        left    : '',
        width   : '',
        top     : ''
      });

      this.redactor.$editor.css('padding-top', 10);

      this.isFixed = false;
    }
  };

  // Hook up plugin to Redactor.
  window.RedactorPlugins = window.RedactorPlugins || {};
  window.RedactorPlugins.fixedtoolbar = function() {
    return {
      init: function () {
        this.fixedtoolbar = new Fixedtoolbar(this);
      }
    };
  };

}(jQuery));

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputRedactor = (function(superClass) {
  extend(InputRedactor, superClass);

  function InputRedactor() {
    return InputRedactor.__super__.constructor.apply(this, arguments);
  }

  InputRedactor.prototype._add_input = function() {
    this.$el.css('opacity', 0);
    this.$input = $("<textarea class='redactor' name='" + this.name + "' rows=1>" + (this._safe_value()) + "</textarea>");
    return this.$el.append(this.$input);
  };

  InputRedactor.prototype.initialize = function() {
    var base, base1, plugins, redactor_options;
    plugins = ['fixedtoolbar'];
    if (Loft) {
      plugins.push('loft');
    }
    redactor_options = {
      focus: false,
      imageFloatMargin: '20px',
      buttonSource: true,
      pastePlainText: true,
      plugins: plugins,
      buttons: ['html', 'formatting', 'bold', 'italic', 'deleted', 'unorderedlist', 'orderedlist', 'link']
    };
    if ((base = this.config).redactorOptions == null) {
      base.redactorOptions = {};
    }
    $.extend(redactor_options, this.config.redactorOptions);
    this.$input.redactor(redactor_options);
    this.$el.css('opacity', 1);
    return typeof (base1 = this.config).onInitialize === "function" ? base1.onInitialize(this) : void 0;
  };

  InputRedactor.prototype.updateValue = function(value) {
    this.value = value;
    return this.$input.redactor('insert.set', this._safe_value());
  };

  return InputRedactor;

})(InputString);

chr.formInputs['redactor'] = InputRedactor;
