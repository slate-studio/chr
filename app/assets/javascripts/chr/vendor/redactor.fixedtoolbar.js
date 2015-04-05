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
