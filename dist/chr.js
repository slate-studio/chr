/*
    Slip - swiping and reordering in lists of elements on touch screens, no fuss.

    Fires these events on list elements:

        • slip:swipe
            When swipe has been done and user has lifted finger off the screen.
            If you execute event.preventDefault() the element will be animated back to original position.
            Otherwise it will be animated off the list and set to display:none.

        • slip:beforeswipe
            Fired before first swipe movement starts.
            If you execute event.preventDefault() then element will not move at all.

        • slip:reorder
            Element has been dropped in new location. event.detail contains the location:
                • insertBefore: DOM node before which element has been dropped (null is the end of the list). Use with node.insertBefore().
                • spliceIndex: Index of element before which current element has been dropped, not counting the element iself.
                               For use with Array.splice() if the list is reflecting objects in some array.

        • slip:beforereorder
            When reordering movement starts.
            Element being reordered gets class `slip-reordering`.
            If you execute event.preventDefault() then element will not move at all.

        • slip:beforewait
            If you execute event.preventDefault() then reordering will begin immediately, blocking ability to scroll the page.

        • slip:tap
            When element was tapped without being swiped/reordered.

        • slip:cancelswipe
            Fired when the user stops dragging and the element returns to its original position.


    Usage:

        CSS:
            You should set `user-select:none` (and WebKit prefixes, sigh) on list elements,
            otherwise unstoppable and glitchy text selection in iOS will get in the way.

            You should set `overflow-x: hidden` on the container or body to prevent horizontal scrollbar
            appearing when elements are swiped off the list.


        var list = document.querySelector('ul#slippylist');
        new Slip(list);

        list.addEventListener('slip:beforeswipe', function(e) {
            if (shouldNotSwipe(e.target)) e.preventDefault();
        });

        list.addEventListener('slip:swipe', function(e) {
            // e.target swiped
            if (thatWasSwipeToRemove) {
                e.target.parentNode.removeChild(e.target);
            } else {
                e.preventDefault(); // will animate back to original position
            }
        });

        list.addEventListener('slip:beforereorder', function(e) {
            if (shouldNotReorder(e.target)) e.preventDefault();
        });

        list.addEventListener('slip:reorder', function(e) {
            // e.target reordered.
            if (reorderedOK) {
                e.target.parentNode.insertBefore(e.target, e.detail.insertBefore);
            } else {
                e.preventDefault();
            }
        });

    Requires:
        • Touch events
        • CSS transforms
        • Function.bind()

    Caveats:
        • Elements must not change size while reordering or swiping takes place (otherwise it will be visually out of sync)
*/
/*! @license
    Slip.js 1.2.0

    © 2014 Kornel Lesiński <kornel@geekhood.net>. All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
       the following disclaimer in the documentation and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
    SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
    USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

window['Slip'] = (function(){
    'use strict';

    var damnYouChrome = /Chrome\/[34]/.test(navigator.userAgent); // For bugs that can't be programmatically detected :( Intended to catch all versions of Chrome 30-40
    var needsBodyHandlerHack = damnYouChrome; // Otherwise I _sometimes_ don't get any touchstart events and only clicks instead.

    /* When dragging elements down in Chrome (tested 34-37) dragged element may appear below stationary elements.
       Looks like WebKit bug #61824, but iOS Safari doesn't have that problem. */
    var compositorDoesNotOrderLayers = damnYouChrome;

    // -webkit-mess
    var testElement = document.createElement('div');

    var transitionPrefix = "webkitTransition" in testElement.style ? "webkitTransition" : "transition";
    var transformPrefix = "webkitTransform" in testElement.style ? "webkitTransform" : "transform";
    var transformProperty = transformPrefix === "webkitTransform" ? "-webkit-transform" : "transform";
    var userSelectPrefix = "webkitUserSelect" in testElement.style ? "webkitUserSelect" : "userSelect";

    testElement.style[transformPrefix] = 'translateZ(0)';
    var hwLayerMagic = testElement.style[transformPrefix] ? 'translateZ(0) ' : '';
    var hwTopLayerMagic = testElement.style[transformPrefix] ? 'translateZ(1px) ' : '';
    testElement = null;

    var globalInstances = 0;
    var attachedBodyHandlerHack = false;
    var nullHandler = function(){};

    function Slip(container, options) {
        if ('string' === typeof container) container = document.querySelector(container);
        if (!container || !container.addEventListener) throw new Error("Please specify DOM node to attach to");

        if (!this || this === window) return new Slip(container, options);

        this.options = options;

        // Functions used for as event handlers need usable `this` and must not change to be removable
        this.cancel = this.setState.bind(this, this.states.idle);
        this.onTouchStart = this.onTouchStart.bind(this);
        this.onTouchMove = this.onTouchMove.bind(this);
        this.onTouchEnd = this.onTouchEnd.bind(this);
        this.onMouseDown = this.onMouseDown.bind(this);
        this.onMouseMove = this.onMouseMove.bind(this);
        this.onMouseUp = this.onMouseUp.bind(this);
        this.onMouseLeave = this.onMouseLeave.bind(this);
        this.onSelection = this.onSelection.bind(this);

        this.setState(this.states.idle);
        this.attach(container);
    }

    function getTransform(node) {
        var transform = node.style[transformPrefix];
        if (transform) {
            return {
                value:transform,
                original:transform,
            };
        }

        if (window.getComputedStyle) {
            var style = window.getComputedStyle(node).getPropertyValue(transformProperty);
            if (style && style !== 'none') return {value:style, original:''};
        }
        return {value:'', original:''};
    }

    function findIndex(target, nodes) {
      var originalIndex = 0;
      var listCount = 0;

      for (var i=0; i < nodes.length; i++) {
        if (nodes[i].nodeType === 1) {
          listCount++;
          if (nodes[i] === target.node) {
            originalIndex = listCount-1;
          }
        }
      }

      return originalIndex;
    }

    // All functions in states are going to be executed in context of Slip object
    Slip.prototype = {

        container: null,
        options: {},
        state: null,

        target: null, // the tapped/swiped/reordered node with height and backed up styles

        usingTouch: false, // there's no good way to detect touchscreen preference other than receiving a touch event (really, trust me).
        mouseHandlersAttached: false,

        startPosition: null, // x,y,time where first touch began
        latestPosition: null, // x,y,time where the finger is currently
        previousPosition: null, // x,y,time where the finger was ~100ms ago (for velocity calculation)

        canPreventScrolling: false,

        states: {
            idle: function idleStateInit() {
                this.target = null;
                this.usingTouch = false;
                this.removeMouseHandlers();

                return {
                    allowTextSelection: true,
                };
            },

            undecided: function undecidedStateInit() {
                this.target.height = this.target.node.offsetHeight;
                this.target.node.style[transitionPrefix] = '';

                if (!this.dispatch(this.target.originalTarget, 'beforewait')) {
                  if (this.dispatch(this.target.originalTarget, 'beforereorder')) {
                    this.setState(this.states.reorder);
                  }
                } else {
                    var holdTimer = setTimeout(function(){
                        var move = this.getAbsoluteMovement();
                        if (this.canPreventScrolling && move.x < 15 && move.y < 25) {
                            if (this.dispatch(this.target.originalTarget, 'beforereorder')) {
                                this.setState(this.states.reorder);
                            }
                        }
                    }.bind(this), 300);
                }

                return {
                    leaveState: function() {
                        clearTimeout(holdTimer);
                    },

                    onMove: function() {
                        var move = this.getAbsoluteMovement();

                        if (move.x > 20 && move.y < Math.max(100, this.target.height)) {
                            if (this.dispatch(this.target.originalTarget, 'beforeswipe')) {
                                this.setState(this.states.swipe);
                                return false;
                            } else {
                                this.setState(this.states.idle);
                            }
                        }
                        if (move.y > 20) {
                            this.setState(this.states.idle);
                        }

                        // Chrome likes sideways scrolling :(
                        if (move.x > move.y*1.2) return false;
                    },

                    onLeave: function() {
                        this.setState(this.states.idle);
                    },

                    onEnd: function() {
                        var allowDefault = this.dispatch(this.target.originalTarget, 'tap');
                        this.setState(this.states.idle);
                        return allowDefault;
                    },
                };
            },

            swipe: function swipeStateInit() {
                var swipeSuccess = false;
                var container = this.container;

                var originalIndex = findIndex(this.target, this.container.childNodes);

                container.className += ' slip-swiping-container';
                function removeClass() {
                    container.className = container.className.replace(/(?:^| )slip-swiping-container/,'');
                }

                this.target.height = this.target.node.offsetHeight;

                return {
                    leaveState: function() {
                        if (swipeSuccess) {
                            this.animateSwipe(function(target){
                                target.node.style[transformPrefix] = target.baseTransform.original;
                                target.node.style[transitionPrefix] = '';
                                if (this.dispatch(target.node, 'afterswipe')) {
                                    removeClass();
                                    return true;
                                } else {
                                    this.animateToZero(undefined, target);
                                }
                            }.bind(this));
                        } else {
                            this.animateToZero(removeClass);
                            this.dispatch(this.target.node, 'cancelswipe');
                        }
                    },

                    onMove: function() {
                        var move = this.getTotalMovement();

                        if (Math.abs(move.y) < this.target.height+20) {
                            this.target.node.style[transformPrefix] = 'translate(' + move.x + 'px,0) ' + hwLayerMagic + this.target.baseTransform.value;
                            return false;
                        } else {
                            this.setState(this.states.idle);
                        }
                    },

                    onLeave: function() {
                        this.state.onEnd.call(this);
                    },

                    onEnd: function() {
                        var dx = this.latestPosition.x - this.previousPosition.x;
                        var dy = this.latestPosition.y - this.previousPosition.y;
                        var velocity = Math.sqrt(dx*dx + dy*dy) / (this.latestPosition.time - this.previousPosition.time + 1);

                        var move = this.getAbsoluteMovement();
                        var swiped = velocity > 0.6 && move.time > 110;

						var direction;
						if (dx > 0) {
							direction = "right";
						} else {
							direction = "left";
						}

                        if (swiped) {
                            if (this.dispatch(this.target.node, 'swipe', {direction: direction, originalIndex: originalIndex})) {
                                swipeSuccess = true; // can't animate here, leaveState overrides anim
                            }
                        }
                        this.setState(this.states.idle);
                        return !swiped;
                    },
                };
            },

            reorder: function reorderStateInit() {
                this.target.height = this.target.node.offsetHeight;

                var nodes = this.container.childNodes;
                var originalIndex = findIndex(this.target, nodes);
                var mouseOutsideTimer;
                var zero = this.target.node.offsetTop + this.target.height/2;
                var otherNodes = [];
                for(var i=0; i < nodes.length; i++) {
                    if (nodes[i].nodeType != 1 || nodes[i] === this.target.node) continue;
                    var t = nodes[i].offsetTop;
                    nodes[i].style[transitionPrefix] = transformProperty + ' 0.2s ease-in-out';
                    otherNodes.push({
                        node: nodes[i],
                        baseTransform: getTransform(nodes[i]),
                        pos: t + (t < zero ? nodes[i].offsetHeight : 0) - zero,
                    });
                }

                this.target.node.className += ' slip-reordering';
                this.target.node.style.zIndex = '99999';
                this.target.node.style[userSelectPrefix] = 'none';
                if (compositorDoesNotOrderLayers) {
                    // Chrome's compositor doesn't sort 2D layers
                    this.container.style.webkitTransformStyle = 'preserve-3d';
                }

                function setPosition() {
                    /*jshint validthis:true */

                    if (mouseOutsideTimer) {
                        // don't care where the mouse is as long as it moves
                        clearTimeout(mouseOutsideTimer); mouseOutsideTimer = null;
                    }

                    var move = this.getTotalMovement();
                    this.target.node.style[transformPrefix] = 'translate(0,' + move.y + 'px) ' + hwTopLayerMagic + this.target.baseTransform.value;

                    var height = this.target.height;
                    otherNodes.forEach(function(o){
                        var off = 0;
                        if (o.pos < 0 && move.y < 0 && o.pos > move.y) {
                            off = height;
                        }
                        else if (o.pos > 0 && move.y > 0 && o.pos < move.y) {
                            off = -height;
                        }
                        // FIXME: should change accelerated/non-accelerated state lazily
                        o.node.style[transformPrefix] = off ? 'translate(0,'+off+'px) ' + hwLayerMagic + o.baseTransform.value : o.baseTransform.original;
                    });
                    return false;
                }

                setPosition.call(this);

                return {
                    leaveState: function() {
                        if (mouseOutsideTimer) clearTimeout(mouseOutsideTimer);

                        if (compositorDoesNotOrderLayers) {
                            this.container.style.webkitTransformStyle = '';
                        }

                        this.target.node.className = this.target.node.className.replace(/(?:^| )slip-reordering/,'');
                        this.target.node.style[userSelectPrefix] = '';

                        this.animateToZero(function(target){
                            target.node.style.zIndex = '';
                        });
                        otherNodes.forEach(function(o){
                            o.node.style[transformPrefix] = o.baseTransform.original;
                            o.node.style[transitionPrefix] = ''; // FIXME: animate to new position
                        });
                    },

                    onMove: setPosition,

                    onLeave: function() {
                        // don't let element get stuck if mouse left the window
                        // but don't cancel immediately as it'd be annoying near window edges
                        if (mouseOutsideTimer) clearTimeout(mouseOutsideTimer);
                        mouseOutsideTimer = setTimeout(function(){
                            mouseOutsideTimer = null;
                            this.cancel();
                        }.bind(this), 700);
                    },

                    onEnd: function() {
                        var move = this.getTotalMovement();
                        if (move.y < 0) {
                            for(var i=0; i < otherNodes.length; i++) {
                                if (otherNodes[i].pos > move.y) {
                                    this.dispatch(this.target.node, 'reorder', {spliceIndex:i, insertBefore:otherNodes[i].node, originalIndex: originalIndex});
                                    break;
                                }
                            }
                        } else {
                            for(var i=otherNodes.length-1; i >= 0; i--) {
                                if (otherNodes[i].pos < move.y) {
                                    this.dispatch(this.target.node, 'reorder', {spliceIndex:i+1, insertBefore:otherNodes[i+1] ? otherNodes[i+1].node : null, originalIndex: originalIndex});
                                    break;
                                }
                            }
                        }
                        this.setState(this.states.idle);
                        return false;
                    },
                };
            },
        },

        attach: function(container) {
            globalInstances++;
            if (this.container) this.detach();

            // In some cases taps on list elements send *only* click events and no touch events. Spotted only in Chrome 32+
            // Having event listener on body seems to solve the issue (although AFAIK may disable smooth scrolling as a side-effect)
            if (!attachedBodyHandlerHack && needsBodyHandlerHack) {
                attachedBodyHandlerHack = true;
                document.body.addEventListener('touchstart', nullHandler, false);
            }

            this.container = container;
            this.otherNodes = [];

            // selection on iOS interferes with reordering
            document.addEventListener("selectionchange", this.onSelection, false);

            // cancel is called e.g. when iOS detects multitasking gesture
            this.container.addEventListener('touchcancel', this.cancel, false);
            this.container.addEventListener('touchstart', this.onTouchStart, false);
            this.container.addEventListener('touchmove', this.onTouchMove, false);
            this.container.addEventListener('touchend', this.onTouchEnd, false);
            this.container.addEventListener('mousedown', this.onMouseDown, false);
            // mousemove and mouseup are attached dynamically
        },

        detach: function() {
            this.cancel();

            this.container.removeEventListener('mousedown', this.onMouseDown, false);
            this.container.removeEventListener('touchend', this.onTouchEnd, false);
            this.container.removeEventListener('touchmove', this.onTouchMove, false);
            this.container.removeEventListener('touchstart', this.onTouchStart, false);
            this.container.removeEventListener('touchcancel', this.cancel, false);

            document.removeEventListener("selectionchange", this.onSelection, false);

            globalInstances--;
            if (!globalInstances && attachedBodyHandlerHack) {
                attachedBodyHandlerHack = false;
                document.body.removeEventListener('touchstart', nullHandler, false);
            }
        },

        setState: function(newStateCtor){
            if (this.state) {
                if (this.state.ctor === newStateCtor) return;
                if (this.state.leaveState) this.state.leaveState.call(this);
            }

            // Must be re-entrant in case ctor changes state
            var prevState = this.state;
            var nextState = newStateCtor.call(this);
            if (this.state === prevState) {
                nextState.ctor = newStateCtor;
                this.state = nextState;
            }
        },

        // Here we have an issue with nested lists, so adding an options
        // for data container, might require to rewrite it without jquery
        findTargetNode: function(target) {
            var targetNode = target;

            while(targetNode && targetNode.parentNode !== this.container) {
                targetNode = targetNode.parentNode;
            }

            var targetContainerClass = $(target).attr('data-container-class');

            if (targetContainerClass) {
                if ( ! $(this.container).hasClass(targetContainerClass) ) {
                    return false;
                }
            }

            return targetNode;
        },

        onSelection: function(e) {
            var isRelated = e.target === document || this.findTargetNode(e);
            if (!isRelated) return;

            if (e.cancelable || e.defaultPrevented) {
                if (!this.state.allowTextSelection) {
                    e.preventDefault();
                }
            } else {
                // iOS doesn't allow selection to be prevented
                this.setState(this.states.idle);
            }
        },

        addMouseHandlers: function() {
            // unlike touch events, mousemove/up is not conveniently fired on the same element,
            // but I don't need to listen to unrelated events all the time
            if (!this.mouseHandlersAttached) {
                this.mouseHandlersAttached = true;
                document.documentElement.addEventListener('mouseleave', this.onMouseLeave, false);
                window.addEventListener('mousemove', this.onMouseMove, true);
                window.addEventListener('mouseup', this.onMouseUp, true);
                window.addEventListener('blur', this.cancel, false);
            }
        },

        removeMouseHandlers: function() {
            if (this.mouseHandlersAttached) {
                this.mouseHandlersAttached = false;
                document.documentElement.removeEventListener('mouseleave', this.onMouseLeave, false);
                window.removeEventListener('mousemove', this.onMouseMove, true);
                window.removeEventListener('mouseup', this.onMouseUp, true);
                window.removeEventListener('blur', this.cancel, false);
            }
        },

        onMouseLeave: function(e) {
            if (this.usingTouch) return;

            if (e.target === document.documentElement || e.relatedTarget === document.documentElement) {
                if (this.state.onLeave) {
                    this.state.onLeave.call(this);
                }
            }
        },

        onMouseDown: function(e) {
            if (this.usingTouch || e.button != 0 || !this.setTarget(e)) return;

            this.addMouseHandlers(); // mouseup, etc.

            this.canPreventScrolling = true; // or rather it doesn't apply to mouse

            this.startAtPosition({
                x: e.clientX,
                y: e.clientY,
                time: e.timeStamp,
            });
        },

        onTouchStart: function(e) {
            this.usingTouch = true;
            this.canPreventScrolling = true;

            // This implementation cares only about single touch
            if (e.touches.length > 1) {
                this.setState(this.states.idle);
                return;
            }

            if (!this.setTarget(e)) return;

            this.startAtPosition({
                x: e.touches[0].clientX,
                y: e.touches[0].clientY - window.scrollY,
                time: e.timeStamp,
            });
        },

        setTarget: function(e) {
            var targetNode = this.findTargetNode(e.target);
            if (!targetNode) {
                this.setState(this.states.idle);
                return false;
            }

            //check for a scrollable parent
            var scrollContainer = targetNode.parentNode;
            while (scrollContainer){
              if (scrollContainer.scrollHeight > scrollContainer.clientHeight && window.getComputedStyle(scrollContainer)['overflow-y'] != 'visible') break;
              else scrollContainer = scrollContainer.parentNode;
            }

            this.target = {
                originalTarget: e.target,
                node: targetNode,
                scrollContainer: scrollContainer,
                baseTransform: getTransform(targetNode),
            };
            return true;
        },

        startAtPosition: function(pos) {
            this.startPosition = this.previousPosition = this.latestPosition = pos;
            this.setState(this.states.undecided);
        },

        updatePosition: function(e, pos) {
            this.latestPosition = pos;

            var triggerOffset = 40,
                offset = 0;

            var scrollable = this.target.scrollContainer || document.body,
                containerRect = scrollable.getBoundingClientRect(),
                targetRect = this.target.node.getBoundingClientRect(),
                bottomOffset = Math.min(containerRect.bottom, window.innerHeight) - targetRect.bottom,
                topOffset = targetRect.top - Math.max(containerRect.top, 0);

            if (bottomOffset < triggerOffset){
              offset = triggerOffset - bottomOffset;
            }
            else if (topOffset < triggerOffset){
              offset = topOffset - triggerOffset;
            }

            var prevScrollTop = scrollable.scrollTop;
            scrollable.scrollTop += offset;
            if (prevScrollTop != scrollable.scrollTop) this.startPosition.y += prevScrollTop-scrollable.scrollTop;

            if (this.state.onMove) {
                if (this.state.onMove.call(this) === false) {
                    e.preventDefault();
                }
            }

            // sample latestPosition 100ms for velocity
            if (this.latestPosition.time - this.previousPosition.time > 100) {
                this.previousPosition = this.latestPosition;
            }
        },

        onMouseMove: function(e) {
            this.updatePosition(e, {
                x: e.clientX,
                y: e.clientY,
                time: e.timeStamp,
            });
        },

        onTouchMove: function(e) {
            this.updatePosition(e, {
                x: e.touches[0].clientX,
                y: e.touches[0].clientY - window.scrollY,
                time: e.timeStamp,
            });

            // In Apple's touch model only the first move event after touchstart can prevent scrolling (and event.cancelable is broken)
            this.canPreventScrolling = false;
        },

        onMouseUp: function(e) {
            if (this.usingTouch || e.button !== 0) return;

            if (this.state.onEnd && false === this.state.onEnd.call(this)) {
                e.preventDefault();
            }
        },

        onTouchEnd: function(e) {
            if (e.touches.length > 1) {
                this.cancel();
            } else if (this.state.onEnd && false === this.state.onEnd.call(this)) {
                e.preventDefault();
            }
        },

        getTotalMovement: function() {
            return {
                x:this.latestPosition.x - this.startPosition.x,
                y:this.latestPosition.y - this.startPosition.y,
            };
        },

        getAbsoluteMovement: function() {
            return {
                x: Math.abs(this.latestPosition.x - this.startPosition.x),
                y: Math.abs(this.latestPosition.y - this.startPosition.y),
                time:this.latestPosition.time - this.startPosition.time,
            };
        },

        dispatch: function(targetNode, eventName, detail) {
            var event = document.createEvent('CustomEvent');
            if (event && event.initCustomEvent) {
                event.initCustomEvent('slip:' + eventName, true, true, detail);
            } else {
                event = document.createEvent('Event');
                event.initEvent('slip:' + eventName, true, true);
                event.detail = detail;
            }
            return targetNode.dispatchEvent(event);
        },

        getSiblings: function(target) {
            var siblings = [];
            var tmp = target.node.nextSibling;
            while(tmp) {
                if (tmp.nodeType == 1) siblings.push({
                    node: tmp,
                    baseTransform: getTransform(tmp),
                });
                tmp = tmp.nextSibling;
            }
            return siblings;
        },

        animateToZero: function(callback, target) {
            // save, because this.target/container could change during animation
            target = target || this.target;

            target.node.style[transitionPrefix] = transformProperty + ' 0.1s ease-out';
            target.node.style[transformPrefix] = 'translate(0,0) ' + hwLayerMagic + target.baseTransform.value;
            setTimeout(function(){
                target.node.style[transitionPrefix] = '';
                target.node.style[transformPrefix] = target.baseTransform.original;
                if (callback) callback.call(this, target);
            }.bind(this), 101);
        },

        animateSwipe: function(callback) {
            var target = this.target;
            var siblings = this.getSiblings(target);
            var emptySpaceTransform = 'translate(0,' + this.target.height + 'px) ' + hwLayerMagic + ' ';

            // FIXME: animate with real velocity
            target.node.style[transitionPrefix] = 'all 0.1s linear';
            target.node.style[transformPrefix] = ' translate(' + (this.getTotalMovement().x > 0 ? '' : '-') + '100%,0) ' + hwLayerMagic + target.baseTransform.value;

            setTimeout(function(){
                if (callback.call(this, target)) {
                    siblings.forEach(function(o){
                        o.node.style[transitionPrefix] = '';
                        o.node.style[transformPrefix] = emptySpaceTransform + o.baseTransform.value;
                    });
                    setTimeout(function(){
                        siblings.forEach(function(o){
                            o.node.style[transitionPrefix] = transformProperty + ' 0.1s ease-in-out';
                            o.node.style[transformPrefix] = 'translate(0,0) ' + hwLayerMagic + o.baseTransform.value;
                        });
                        setTimeout(function(){
                            siblings.forEach(function(o){
                                o.node.style[transitionPrefix] = '';
                                o.node.style[transformPrefix] = o.baseTransform.original;
                            });
                        },101);
                    }, 1);
                }
            }.bind(this), 101);
        },
    };

    // AMD
    if ('function' === typeof define && define.amd) {
        define(function(){
            return Slip;
        });
    }
    return Slip;
})();


// https://github.com/slindberg/jquery-scrollparent
jQuery.fn.scrollParent = function() {
  var position = this.css( "position" ),
  excludeStaticParent = position === "absolute",
  scrollParent = this.parents().filter( function() {
    var parent = $( this );
    if ( excludeStaticParent && parent.css( "position" ) === "static" ) {
      return false;
    }
    return (/(auto|scroll)/).test( parent.css( "overflow" ) + parent.css( "overflow-y" ) + parent.css( "overflow-x" ) );
  }).eq( 0 );

  return position === "fixed" || !scrollParent.length ? $( this[ 0 ].ownerDocument || document ) : scrollParent;
};
// https://github.com/javierjulio/textarea-autosize
/*!
 * jQuery Textarea AutoSize plugin
 * Author: Javier Julio
 * Licensed under the MIT license
 */
;(function ($, window, document, undefined) {

  var pluginName = "textareaAutoSize";
  var pluginDataName = "plugin_" + pluginName;

  var containsText = function (value) {
    return (value.replace(/\s/g, '').length > 0);
  };

  function Plugin(element, options) {
    this.element = element;
    this.$element = $(element);
    this.init();
  }

  Plugin.prototype = {
    init: function() {
      var height = this.$element.outerHeight();
      var diff = parseInt(this.$element.css('paddingBottom')) +
                  parseInt(this.$element.css('paddingTop'));

      if (containsText(this.element.value)) {
        this.$element.height(this.element.scrollHeight - diff);
      }

      // keyup is required for IE to properly reset height when deleting text
      this.$element.on('input keyup', function(event) {
        var $scrollParent = $(this).scrollParent();
        var currentScrollPosition = $scrollParent.scrollTop();

        $(this)
          .height(0)
          .height(this.scrollHeight - diff);

        $scrollParent.scrollTop(currentScrollPosition);
      });
    }
  };

  $.fn[pluginName] = function (options) {
    this.each(function() {
      if (!$.data(this, pluginDataName)) {
        $.data(this, pluginDataName, new Plugin(this, options));
      }
    });
    return this;
  };

})(jQuery, window, document);
/*!
 * typeahead.js 0.10.5
 * https://github.com/twitter/typeahead.js
 * Copyright 2013-2014 Twitter, Inc. and other contributors; Licensed MIT
 */

(function($) {
    var _ = function() {
        "use strict";
        return {
            isMsie: function() {
                return /(msie|trident)/i.test(navigator.userAgent) ? navigator.userAgent.match(/(msie |rv:)(\d+(.\d+)?)/i)[2] : false;
            },
            isBlankString: function(str) {
                return !str || /^\s*$/.test(str);
            },
            escapeRegExChars: function(str) {
                return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
            },
            isString: function(obj) {
                return typeof obj === "string";
            },
            isNumber: function(obj) {
                return typeof obj === "number";
            },
            isArray: $.isArray,
            isFunction: $.isFunction,
            isObject: $.isPlainObject,
            isUndefined: function(obj) {
                return typeof obj === "undefined";
            },
            toStr: function toStr(s) {
                return _.isUndefined(s) || s === null ? "" : s + "";
            },
            bind: $.proxy,
            each: function(collection, cb) {
                $.each(collection, reverseArgs);
                function reverseArgs(index, value) {
                    return cb(value, index);
                }
            },
            map: $.map,
            filter: $.grep,
            every: function(obj, test) {
                var result = true;
                if (!obj) {
                    return result;
                }
                $.each(obj, function(key, val) {
                    if (!(result = test.call(null, val, key, obj))) {
                        return false;
                    }
                });
                return !!result;
            },
            some: function(obj, test) {
                var result = false;
                if (!obj) {
                    return result;
                }
                $.each(obj, function(key, val) {
                    if (result = test.call(null, val, key, obj)) {
                        return false;
                    }
                });
                return !!result;
            },
            mixin: $.extend,
            getUniqueId: function() {
                var counter = 0;
                return function() {
                    return counter++;
                };
            }(),
            templatify: function templatify(obj) {
                return $.isFunction(obj) ? obj : template;
                function template() {
                    return String(obj);
                }
            },
            defer: function(fn) {
                setTimeout(fn, 0);
            },
            debounce: function(func, wait, immediate) {
                var timeout, result;
                return function() {
                    var context = this, args = arguments, later, callNow;
                    later = function() {
                        timeout = null;
                        if (!immediate) {
                            result = func.apply(context, args);
                        }
                    };
                    callNow = immediate && !timeout;
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                    if (callNow) {
                        result = func.apply(context, args);
                    }
                    return result;
                };
            },
            throttle: function(func, wait) {
                var context, args, timeout, result, previous, later;
                previous = 0;
                later = function() {
                    previous = new Date();
                    timeout = null;
                    result = func.apply(context, args);
                };
                return function() {
                    var now = new Date(), remaining = wait - (now - previous);
                    context = this;
                    args = arguments;
                    if (remaining <= 0) {
                        clearTimeout(timeout);
                        timeout = null;
                        previous = now;
                        result = func.apply(context, args);
                    } else if (!timeout) {
                        timeout = setTimeout(later, remaining);
                    }
                    return result;
                };
            },
            noop: function() {}
        };
    }();
    var VERSION = "0.10.5";
    var tokenizers = function() {
        "use strict";
        return {
            nonword: nonword,
            whitespace: whitespace,
            obj: {
                nonword: getObjTokenizer(nonword),
                whitespace: getObjTokenizer(whitespace)
            }
        };
        function whitespace(str) {
            str = _.toStr(str);
            return str ? str.split(/\s+/) : [];
        }
        function nonword(str) {
            str = _.toStr(str);
            return str ? str.split(/\W+/) : [];
        }
        function getObjTokenizer(tokenizer) {
            return function setKey() {
                var args = [].slice.call(arguments, 0);
                return function tokenize(o) {
                    var tokens = [];
                    _.each(args, function(k) {
                        tokens = tokens.concat(tokenizer(_.toStr(o[k])));
                    });
                    return tokens;
                };
            };
        }
    }();
    var LruCache = function() {
        "use strict";
        function LruCache(maxSize) {
            this.maxSize = _.isNumber(maxSize) ? maxSize : 100;
            this.reset();
            if (this.maxSize <= 0) {
                this.set = this.get = $.noop;
            }
        }
        _.mixin(LruCache.prototype, {
            set: function set(key, val) {
                var tailItem = this.list.tail, node;
                if (this.size >= this.maxSize) {
                    this.list.remove(tailItem);
                    delete this.hash[tailItem.key];
                }
                if (node = this.hash[key]) {
                    node.val = val;
                    this.list.moveToFront(node);
                } else {
                    node = new Node(key, val);
                    this.list.add(node);
                    this.hash[key] = node;
                    this.size++;
                }
            },
            get: function get(key) {
                var node = this.hash[key];
                if (node) {
                    this.list.moveToFront(node);
                    return node.val;
                }
            },
            reset: function reset() {
                this.size = 0;
                this.hash = {};
                this.list = new List();
            }
        });
        function List() {
            this.head = this.tail = null;
        }
        _.mixin(List.prototype, {
            add: function add(node) {
                if (this.head) {
                    node.next = this.head;
                    this.head.prev = node;
                }
                this.head = node;
                this.tail = this.tail || node;
            },
            remove: function remove(node) {
                node.prev ? node.prev.next = node.next : this.head = node.next;
                node.next ? node.next.prev = node.prev : this.tail = node.prev;
            },
            moveToFront: function(node) {
                this.remove(node);
                this.add(node);
            }
        });
        function Node(key, val) {
            this.key = key;
            this.val = val;
            this.prev = this.next = null;
        }
        return LruCache;
    }();
    var PersistentStorage = function() {
        "use strict";
        var ls, methods;
        try {
            ls = window.localStorage;
            ls.setItem("~~~", "!");
            ls.removeItem("~~~");
        } catch (err) {
            ls = null;
        }
        function PersistentStorage(namespace) {
            this.prefix = [ "__", namespace, "__" ].join("");
            this.ttlKey = "__ttl__";
            this.keyMatcher = new RegExp("^" + _.escapeRegExChars(this.prefix));
        }
        if (ls && window.JSON) {
            methods = {
                _prefix: function(key) {
                    return this.prefix + key;
                },
                _ttlKey: function(key) {
                    return this._prefix(key) + this.ttlKey;
                },
                get: function(key) {
                    if (this.isExpired(key)) {
                        this.remove(key);
                    }
                    return decode(ls.getItem(this._prefix(key)));
                },
                set: function(key, val, ttl) {
                    if (_.isNumber(ttl)) {
                        ls.setItem(this._ttlKey(key), encode(now() + ttl));
                    } else {
                        ls.removeItem(this._ttlKey(key));
                    }
                    return ls.setItem(this._prefix(key), encode(val));
                },
                remove: function(key) {
                    ls.removeItem(this._ttlKey(key));
                    ls.removeItem(this._prefix(key));
                    return this;
                },
                clear: function() {
                    var i, key, keys = [], len = ls.length;
                    for (i = 0; i < len; i++) {
                        if ((key = ls.key(i)).match(this.keyMatcher)) {
                            keys.push(key.replace(this.keyMatcher, ""));
                        }
                    }
                    for (i = keys.length; i--; ) {
                        this.remove(keys[i]);
                    }
                    return this;
                },
                isExpired: function(key) {
                    var ttl = decode(ls.getItem(this._ttlKey(key)));
                    return _.isNumber(ttl) && now() > ttl ? true : false;
                }
            };
        } else {
            methods = {
                get: _.noop,
                set: _.noop,
                remove: _.noop,
                clear: _.noop,
                isExpired: _.noop
            };
        }
        _.mixin(PersistentStorage.prototype, methods);
        return PersistentStorage;
        function now() {
            return new Date().getTime();
        }
        function encode(val) {
            return JSON.stringify(_.isUndefined(val) ? null : val);
        }
        function decode(val) {
            return JSON.parse(val);
        }
    }();
    var Transport = function() {
        "use strict";
        var pendingRequestsCount = 0, pendingRequests = {}, maxPendingRequests = 6, sharedCache = new LruCache(10);
        function Transport(o) {
            o = o || {};
            this.cancelled = false;
            this.lastUrl = null;
            this._send = o.transport ? callbackToDeferred(o.transport) : $.ajax;
            this._get = o.rateLimiter ? o.rateLimiter(this._get) : this._get;
            this._cache = o.cache === false ? new LruCache(0) : sharedCache;
        }
        Transport.setMaxPendingRequests = function setMaxPendingRequests(num) {
            maxPendingRequests = num;
        };
        Transport.resetCache = function resetCache() {
            sharedCache.reset();
        };
        _.mixin(Transport.prototype, {
            _get: function(url, o, cb) {
                var that = this, jqXhr;
                if (this.cancelled || url !== this.lastUrl) {
                    return;
                }
                if (jqXhr = pendingRequests[url]) {
                    jqXhr.done(done).fail(fail);
                } else if (pendingRequestsCount < maxPendingRequests) {
                    pendingRequestsCount++;
                    pendingRequests[url] = this._send(url, o).done(done).fail(fail).always(always);
                } else {
                    this.onDeckRequestArgs = [].slice.call(arguments, 0);
                }
                function done(resp) {
                    cb && cb(null, resp);
                    that._cache.set(url, resp);
                }
                function fail() {
                    cb && cb(true);
                }
                function always() {
                    pendingRequestsCount--;
                    delete pendingRequests[url];
                    if (that.onDeckRequestArgs) {
                        that._get.apply(that, that.onDeckRequestArgs);
                        that.onDeckRequestArgs = null;
                    }
                }
            },
            get: function(url, o, cb) {
                var resp;
                if (_.isFunction(o)) {
                    cb = o;
                    o = {};
                }
                this.cancelled = false;
                this.lastUrl = url;
                if (resp = this._cache.get(url)) {
                    _.defer(function() {
                        cb && cb(null, resp);
                    });
                } else {
                    this._get(url, o, cb);
                }
                return !!resp;
            },
            cancel: function() {
                this.cancelled = true;
            }
        });
        return Transport;
        function callbackToDeferred(fn) {
            return function customSendWrapper(url, o) {
                var deferred = $.Deferred();
                fn(url, o, onSuccess, onError);
                return deferred;
                function onSuccess(resp) {
                    _.defer(function() {
                        deferred.resolve(resp);
                    });
                }
                function onError(err) {
                    _.defer(function() {
                        deferred.reject(err);
                    });
                }
            };
        }
    }();
    var SearchIndex = function() {
        "use strict";
        function SearchIndex(o) {
            o = o || {};
            if (!o.datumTokenizer || !o.queryTokenizer) {
                $.error("datumTokenizer and queryTokenizer are both required");
            }
            this.datumTokenizer = o.datumTokenizer;
            this.queryTokenizer = o.queryTokenizer;
            this.reset();
        }
        _.mixin(SearchIndex.prototype, {
            bootstrap: function bootstrap(o) {
                this.datums = o.datums;
                this.trie = o.trie;
            },
            add: function(data) {
                var that = this;
                data = _.isArray(data) ? data : [ data ];
                _.each(data, function(datum) {
                    var id, tokens;
                    id = that.datums.push(datum) - 1;
                    tokens = normalizeTokens(that.datumTokenizer(datum));
                    _.each(tokens, function(token) {
                        var node, chars, ch;
                        node = that.trie;
                        chars = token.split("");
                        while (ch = chars.shift()) {
                            node = node.children[ch] || (node.children[ch] = newNode());
                            node.ids.push(id);
                        }
                    });
                });
            },
            get: function get(query) {
                var that = this, tokens, matches;
                tokens = normalizeTokens(this.queryTokenizer(query));
                _.each(tokens, function(token) {
                    var node, chars, ch, ids;
                    if (matches && matches.length === 0) {
                        return false;
                    }
                    node = that.trie;
                    chars = token.split("");
                    while (node && (ch = chars.shift())) {
                        node = node.children[ch];
                    }
                    if (node && chars.length === 0) {
                        ids = node.ids.slice(0);
                        matches = matches ? getIntersection(matches, ids) : ids;
                    } else {
                        matches = [];
                        return false;
                    }
                });
                return matches ? _.map(unique(matches), function(id) {
                    return that.datums[id];
                }) : [];
            },
            reset: function reset() {
                this.datums = [];
                this.trie = newNode();
            },
            serialize: function serialize() {
                return {
                    datums: this.datums,
                    trie: this.trie
                };
            }
        });
        return SearchIndex;
        function normalizeTokens(tokens) {
            tokens = _.filter(tokens, function(token) {
                return !!token;
            });
            tokens = _.map(tokens, function(token) {
                return token.toLowerCase();
            });
            return tokens;
        }
        function newNode() {
            return {
                ids: [],
                children: {}
            };
        }
        function unique(array) {
            var seen = {}, uniques = [];
            for (var i = 0, len = array.length; i < len; i++) {
                if (!seen[array[i]]) {
                    seen[array[i]] = true;
                    uniques.push(array[i]);
                }
            }
            return uniques;
        }
        function getIntersection(arrayA, arrayB) {
            var ai = 0, bi = 0, intersection = [];
            arrayA = arrayA.sort(compare);
            arrayB = arrayB.sort(compare);
            var lenArrayA = arrayA.length, lenArrayB = arrayB.length;
            while (ai < lenArrayA && bi < lenArrayB) {
                if (arrayA[ai] < arrayB[bi]) {
                    ai++;
                } else if (arrayA[ai] > arrayB[bi]) {
                    bi++;
                } else {
                    intersection.push(arrayA[ai]);
                    ai++;
                    bi++;
                }
            }
            return intersection;
            function compare(a, b) {
                return a - b;
            }
        }
    }();
    var oParser = function() {
        "use strict";
        return {
            local: getLocal,
            prefetch: getPrefetch,
            remote: getRemote
        };
        function getLocal(o) {
            return o.local || null;
        }
        function getPrefetch(o) {
            var prefetch, defaults;
            defaults = {
                url: null,
                thumbprint: "",
                ttl: 24 * 60 * 60 * 1e3,
                filter: null,
                ajax: {}
            };
            if (prefetch = o.prefetch || null) {
                prefetch = _.isString(prefetch) ? {
                    url: prefetch
                } : prefetch;
                prefetch = _.mixin(defaults, prefetch);
                prefetch.thumbprint = VERSION + prefetch.thumbprint;
                prefetch.ajax.type = prefetch.ajax.type || "GET";
                prefetch.ajax.dataType = prefetch.ajax.dataType || "json";
                !prefetch.url && $.error("prefetch requires url to be set");
            }
            return prefetch;
        }
        function getRemote(o) {
            var remote, defaults;
            defaults = {
                url: null,
                cache: true,
                wildcard: "%QUERY",
                replace: null,
                rateLimitBy: "debounce",
                rateLimitWait: 300,
                send: null,
                filter: null,
                ajax: {}
            };
            if (remote = o.remote || null) {
                remote = _.isString(remote) ? {
                    url: remote
                } : remote;
                remote = _.mixin(defaults, remote);
                remote.rateLimiter = /^throttle$/i.test(remote.rateLimitBy) ? byThrottle(remote.rateLimitWait) : byDebounce(remote.rateLimitWait);
                remote.ajax.type = remote.ajax.type || "GET";
                remote.ajax.dataType = remote.ajax.dataType || "json";
                delete remote.rateLimitBy;
                delete remote.rateLimitWait;
                !remote.url && $.error("remote requires url to be set");
            }
            return remote;
            function byDebounce(wait) {
                return function(fn) {
                    return _.debounce(fn, wait);
                };
            }
            function byThrottle(wait) {
                return function(fn) {
                    return _.throttle(fn, wait);
                };
            }
        }
    }();
    (function(root) {
        "use strict";
        var old, keys;
        old = root.Bloodhound;
        keys = {
            data: "data",
            protocol: "protocol",
            thumbprint: "thumbprint"
        };
        root.Bloodhound = Bloodhound;
        function Bloodhound(o) {
            if (!o || !o.local && !o.prefetch && !o.remote) {
                $.error("one of local, prefetch, or remote is required");
            }
            this.limit = o.limit || 5;
            this.sorter = getSorter(o.sorter);
            this.dupDetector = o.dupDetector || ignoreDuplicates;
            this.local = oParser.local(o);
            this.prefetch = oParser.prefetch(o);
            this.remote = oParser.remote(o);
            this.cacheKey = this.prefetch ? this.prefetch.cacheKey || this.prefetch.url : null;
            this.index = new SearchIndex({
                datumTokenizer: o.datumTokenizer,
                queryTokenizer: o.queryTokenizer
            });
            this.storage = this.cacheKey ? new PersistentStorage(this.cacheKey) : null;
        }
        Bloodhound.noConflict = function noConflict() {
            root.Bloodhound = old;
            return Bloodhound;
        };
        Bloodhound.tokenizers = tokenizers;
        _.mixin(Bloodhound.prototype, {
            _loadPrefetch: function loadPrefetch(o) {
                var that = this, serialized, deferred;
                if (serialized = this._readFromStorage(o.thumbprint)) {
                    this.index.bootstrap(serialized);
                    deferred = $.Deferred().resolve();
                } else {
                    deferred = $.ajax(o.url, o.ajax).done(handlePrefetchResponse);
                }
                return deferred;
                function handlePrefetchResponse(resp) {
                    that.clear();
                    that.add(o.filter ? o.filter(resp) : resp);
                    that._saveToStorage(that.index.serialize(), o.thumbprint, o.ttl);
                }
            },
            _getFromRemote: function getFromRemote(query, cb) {
                var that = this, url, uriEncodedQuery;
                if (!this.transport) {
                    return;
                }
                query = query || "";
                uriEncodedQuery = encodeURIComponent(query);
                url = this.remote.replace ? this.remote.replace(this.remote.url, query) : this.remote.url.replace(this.remote.wildcard, uriEncodedQuery);
                return this.transport.get(url, this.remote.ajax, handleRemoteResponse);
                function handleRemoteResponse(err, resp) {
                    err ? cb([]) : cb(that.remote.filter ? that.remote.filter(resp) : resp);
                }
            },
            _cancelLastRemoteRequest: function cancelLastRemoteRequest() {
                this.transport && this.transport.cancel();
            },
            _saveToStorage: function saveToStorage(data, thumbprint, ttl) {
                if (this.storage) {
                    this.storage.set(keys.data, data, ttl);
                    this.storage.set(keys.protocol, location.protocol, ttl);
                    this.storage.set(keys.thumbprint, thumbprint, ttl);
                }
            },
            _readFromStorage: function readFromStorage(thumbprint) {
                var stored = {}, isExpired;
                if (this.storage) {
                    stored.data = this.storage.get(keys.data);
                    stored.protocol = this.storage.get(keys.protocol);
                    stored.thumbprint = this.storage.get(keys.thumbprint);
                }
                isExpired = stored.thumbprint !== thumbprint || stored.protocol !== location.protocol;
                return stored.data && !isExpired ? stored.data : null;
            },
            _initialize: function initialize() {
                var that = this, local = this.local, deferred;
                deferred = this.prefetch ? this._loadPrefetch(this.prefetch) : $.Deferred().resolve();
                local && deferred.done(addLocalToIndex);
                this.transport = this.remote ? new Transport(this.remote) : null;
                return this.initPromise = deferred.promise();
                function addLocalToIndex() {
                    that.add(_.isFunction(local) ? local() : local);
                }
            },
            initialize: function initialize(force) {
                return !this.initPromise || force ? this._initialize() : this.initPromise;
            },
            add: function add(data) {
                this.index.add(data);
            },
            get: function get(query, cb) {
                var that = this, matches = [], cacheHit = false;
                matches = this.index.get(query);
                matches = this.sorter(matches).slice(0, this.limit);
                matches.length < this.limit ? cacheHit = this._getFromRemote(query, returnRemoteMatches) : this._cancelLastRemoteRequest();
                if (!cacheHit) {
                    (matches.length > 0 || !this.transport) && cb && cb(matches);
                }
                function returnRemoteMatches(remoteMatches) {
                    var matchesWithBackfill = matches.slice(0);
                    _.each(remoteMatches, function(remoteMatch) {
                        var isDuplicate;
                        isDuplicate = _.some(matchesWithBackfill, function(match) {
                            return that.dupDetector(remoteMatch, match);
                        });
                        !isDuplicate && matchesWithBackfill.push(remoteMatch);
                        return matchesWithBackfill.length < that.limit;
                    });
                    cb && cb(that.sorter(matchesWithBackfill));
                }
            },
            clear: function clear() {
                this.index.reset();
            },
            clearPrefetchCache: function clearPrefetchCache() {
                this.storage && this.storage.clear();
            },
            clearRemoteCache: function clearRemoteCache() {
                this.transport && Transport.resetCache();
            },
            ttAdapter: function ttAdapter() {
                return _.bind(this.get, this);
            }
        });
        return Bloodhound;
        function getSorter(sortFn) {
            return _.isFunction(sortFn) ? sort : noSort;
            function sort(array) {
                return array.sort(sortFn);
            }
            function noSort(array) {
                return array;
            }
        }
        function ignoreDuplicates() {
            return false;
        }
    })(this);
    var html = function() {
        return {
            wrapper: '<span class="twitter-typeahead"></span>',
            dropdown: '<span class="tt-dropdown-menu"></span>',
            dataset: '<div class="tt-dataset-%CLASS%"></div>',
            suggestions: '<span class="tt-suggestions"></span>',
            suggestion: '<div class="tt-suggestion"></div>'
        };
    }();
    var css = function() {
        "use strict";
        var css = {
            wrapper: {
                position: "relative",
                display: "inline-block"
            },
            hint: {
                position: "absolute",
                top: "0",
                left: "0",
                borderColor: "transparent",
                boxShadow: "none",
                opacity: "1"
            },
            input: {
                position: "relative",
                verticalAlign: "top",
                backgroundColor: "transparent"
            },
            inputWithNoHint: {
                position: "relative",
                verticalAlign: "top"
            },
            dropdown: {
                position: "absolute",
                top: "100%",
                left: "0",
                zIndex: "100",
                display: "none"
            },
            suggestions: {
                display: "block"
            },
            suggestion: {
                whiteSpace: "nowrap",
                cursor: "pointer"
            },
            suggestionChild: {
                whiteSpace: "normal"
            },
            ltr: {
                left: "0",
                right: "auto"
            },
            rtl: {
                left: "auto",
                right: " 0"
            }
        };
        if (_.isMsie()) {
            _.mixin(css.input, {
                backgroundImage: "url(data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7)"
            });
        }
        if (_.isMsie() && _.isMsie() <= 7) {
            _.mixin(css.input, {
                marginTop: "-1px"
            });
        }
        return css;
    }();
    var EventBus = function() {
        "use strict";
        var namespace = "typeahead:";
        function EventBus(o) {
            if (!o || !o.el) {
                $.error("EventBus initialized without el");
            }
            this.$el = $(o.el);
        }
        _.mixin(EventBus.prototype, {
            trigger: function(type) {
                var args = [].slice.call(arguments, 1);
                this.$el.trigger(namespace + type, args);
            }
        });
        return EventBus;
    }();
    var EventEmitter = function() {
        "use strict";
        var splitter = /\s+/, nextTick = getNextTick();
        return {
            onSync: onSync,
            onAsync: onAsync,
            off: off,
            trigger: trigger
        };
        function on(method, types, cb, context) {
            var type;
            if (!cb) {
                return this;
            }
            types = types.split(splitter);
            cb = context ? bindContext(cb, context) : cb;
            this._callbacks = this._callbacks || {};
            while (type = types.shift()) {
                this._callbacks[type] = this._callbacks[type] || {
                    sync: [],
                    async: []
                };
                this._callbacks[type][method].push(cb);
            }
            return this;
        }
        function onAsync(types, cb, context) {
            return on.call(this, "async", types, cb, context);
        }
        function onSync(types, cb, context) {
            return on.call(this, "sync", types, cb, context);
        }
        function off(types) {
            var type;
            if (!this._callbacks) {
                return this;
            }
            types = types.split(splitter);
            while (type = types.shift()) {
                delete this._callbacks[type];
            }
            return this;
        }
        function trigger(types) {
            var type, callbacks, args, syncFlush, asyncFlush;
            if (!this._callbacks) {
                return this;
            }
            types = types.split(splitter);
            args = [].slice.call(arguments, 1);
            while ((type = types.shift()) && (callbacks = this._callbacks[type])) {
                syncFlush = getFlush(callbacks.sync, this, [ type ].concat(args));
                asyncFlush = getFlush(callbacks.async, this, [ type ].concat(args));
                syncFlush() && nextTick(asyncFlush);
            }
            return this;
        }
        function getFlush(callbacks, context, args) {
            return flush;
            function flush() {
                var cancelled;
                for (var i = 0, len = callbacks.length; !cancelled && i < len; i += 1) {
                    cancelled = callbacks[i].apply(context, args) === false;
                }
                return !cancelled;
            }
        }
        function getNextTick() {
            var nextTickFn;
            if (window.setImmediate) {
                nextTickFn = function nextTickSetImmediate(fn) {
                    setImmediate(function() {
                        fn();
                    });
                };
            } else {
                nextTickFn = function nextTickSetTimeout(fn) {
                    setTimeout(function() {
                        fn();
                    }, 0);
                };
            }
            return nextTickFn;
        }
        function bindContext(fn, context) {
            return fn.bind ? fn.bind(context) : function() {
                fn.apply(context, [].slice.call(arguments, 0));
            };
        }
    }();
    var highlight = function(doc) {
        "use strict";
        var defaults = {
            node: null,
            pattern: null,
            tagName: "strong",
            className: null,
            wordsOnly: false,
            caseSensitive: false
        };
        return function hightlight(o) {
            var regex;
            o = _.mixin({}, defaults, o);
            if (!o.node || !o.pattern) {
                return;
            }
            o.pattern = _.isArray(o.pattern) ? o.pattern : [ o.pattern ];
            regex = getRegex(o.pattern, o.caseSensitive, o.wordsOnly);
            traverse(o.node, hightlightTextNode);
            function hightlightTextNode(textNode) {
                var match, patternNode, wrapperNode;
                if (match = regex.exec(textNode.data)) {
                    wrapperNode = doc.createElement(o.tagName);
                    o.className && (wrapperNode.className = o.className);
                    patternNode = textNode.splitText(match.index);
                    patternNode.splitText(match[0].length);
                    wrapperNode.appendChild(patternNode.cloneNode(true));
                    textNode.parentNode.replaceChild(wrapperNode, patternNode);
                }
                return !!match;
            }
            function traverse(el, hightlightTextNode) {
                var childNode, TEXT_NODE_TYPE = 3;
                for (var i = 0; i < el.childNodes.length; i++) {
                    childNode = el.childNodes[i];
                    if (childNode.nodeType === TEXT_NODE_TYPE) {
                        i += hightlightTextNode(childNode) ? 1 : 0;
                    } else {
                        traverse(childNode, hightlightTextNode);
                    }
                }
            }
        };
        function getRegex(patterns, caseSensitive, wordsOnly) {
            var escapedPatterns = [], regexStr;
            for (var i = 0, len = patterns.length; i < len; i++) {
                escapedPatterns.push(_.escapeRegExChars(patterns[i]));
            }
            regexStr = wordsOnly ? "\\b(" + escapedPatterns.join("|") + ")\\b" : "(" + escapedPatterns.join("|") + ")";
            return caseSensitive ? new RegExp(regexStr) : new RegExp(regexStr, "i");
        }
    }(window.document);
    var Input = function() {
        "use strict";
        var specialKeyCodeMap;
        specialKeyCodeMap = {
            9: "tab",
            27: "esc",
            37: "left",
            39: "right",
            13: "enter",
            38: "up",
            40: "down"
        };
        function Input(o) {
            var that = this, onBlur, onFocus, onKeydown, onInput;
            o = o || {};
            if (!o.input) {
                $.error("input is missing");
            }
            onBlur = _.bind(this._onBlur, this);
            onFocus = _.bind(this._onFocus, this);
            onKeydown = _.bind(this._onKeydown, this);
            onInput = _.bind(this._onInput, this);
            this.$hint = $(o.hint);
            this.$input = $(o.input).on("blur.tt", onBlur).on("focus.tt", onFocus).on("keydown.tt", onKeydown);
            if (this.$hint.length === 0) {
                this.setHint = this.getHint = this.clearHint = this.clearHintIfInvalid = _.noop;
            }
            if (!_.isMsie()) {
                this.$input.on("input.tt", onInput);
            } else {
                this.$input.on("keydown.tt keypress.tt cut.tt paste.tt", function($e) {
                    if (specialKeyCodeMap[$e.which || $e.keyCode]) {
                        return;
                    }
                    _.defer(_.bind(that._onInput, that, $e));
                });
            }
            this.query = this.$input.val();
            this.$overflowHelper = buildOverflowHelper(this.$input);
        }
        Input.normalizeQuery = function(str) {
            return (str || "").replace(/^\s*/g, "").replace(/\s{2,}/g, " ");
        };
        _.mixin(Input.prototype, EventEmitter, {
            _onBlur: function onBlur() {
                this.resetInputValue();
                this.trigger("blurred");
            },
            _onFocus: function onFocus() {
                this.trigger("focused");
            },
            _onKeydown: function onKeydown($e) {
                var keyName = specialKeyCodeMap[$e.which || $e.keyCode];
                this._managePreventDefault(keyName, $e);
                if (keyName && this._shouldTrigger(keyName, $e)) {
                    this.trigger(keyName + "Keyed", $e);
                }
            },
            _onInput: function onInput() {
                this._checkInputValue();
            },
            _managePreventDefault: function managePreventDefault(keyName, $e) {
                var preventDefault, hintValue, inputValue;
                switch (keyName) {
                  case "tab":
                    hintValue = this.getHint();
                    inputValue = this.getInputValue();
                    preventDefault = hintValue && hintValue !== inputValue && !withModifier($e);
                    break;

                  case "up":
                  case "down":
                    preventDefault = !withModifier($e);
                    break;

                  default:
                    preventDefault = false;
                }
                preventDefault && $e.preventDefault();
            },
            _shouldTrigger: function shouldTrigger(keyName, $e) {
                var trigger;
                switch (keyName) {
                  case "tab":
                    trigger = !withModifier($e);
                    break;

                  default:
                    trigger = true;
                }
                return trigger;
            },
            _checkInputValue: function checkInputValue() {
                var inputValue, areEquivalent, hasDifferentWhitespace;
                inputValue = this.getInputValue();
                areEquivalent = areQueriesEquivalent(inputValue, this.query);
                hasDifferentWhitespace = areEquivalent ? this.query.length !== inputValue.length : false;
                this.query = inputValue;
                if (!areEquivalent) {
                    this.trigger("queryChanged", this.query);
                } else if (hasDifferentWhitespace) {
                    this.trigger("whitespaceChanged", this.query);
                }
            },
            focus: function focus() {
                this.$input.focus();
            },
            blur: function blur() {
                this.$input.blur();
            },
            getQuery: function getQuery() {
                return this.query;
            },
            setQuery: function setQuery(query) {
                this.query = query;
            },
            getInputValue: function getInputValue() {
                return this.$input.val();
            },
            setInputValue: function setInputValue(value, silent) {
                this.$input.val(value);
                silent ? this.clearHint() : this._checkInputValue();
            },
            resetInputValue: function resetInputValue() {
                this.setInputValue(this.query, true);
            },
            getHint: function getHint() {
                return this.$hint.val();
            },
            setHint: function setHint(value) {
                this.$hint.val(value);
            },
            clearHint: function clearHint() {
                this.setHint("");
            },
            clearHintIfInvalid: function clearHintIfInvalid() {
                var val, hint, valIsPrefixOfHint, isValid;
                val = this.getInputValue();
                hint = this.getHint();
                valIsPrefixOfHint = val !== hint && hint.indexOf(val) === 0;
                isValid = val !== "" && valIsPrefixOfHint && !this.hasOverflow();
                !isValid && this.clearHint();
            },
            getLanguageDirection: function getLanguageDirection() {
                return (this.$input.css("direction") || "ltr").toLowerCase();
            },
            hasOverflow: function hasOverflow() {
                var constraint = this.$input.width() - 2;
                this.$overflowHelper.text(this.getInputValue());
                return this.$overflowHelper.width() >= constraint;
            },
            isCursorAtEnd: function() {
                var valueLength, selectionStart, range;
                valueLength = this.$input.val().length;
                selectionStart = this.$input[0].selectionStart;
                if (_.isNumber(selectionStart)) {
                    return selectionStart === valueLength;
                } else if (document.selection) {
                    range = document.selection.createRange();
                    range.moveStart("character", -valueLength);
                    return valueLength === range.text.length;
                }
                return true;
            },
            destroy: function destroy() {
                this.$hint.off(".tt");
                this.$input.off(".tt");
                this.$hint = this.$input = this.$overflowHelper = null;
            }
        });
        return Input;
        function buildOverflowHelper($input) {
            return $('<pre aria-hidden="true"></pre>').css({
                position: "absolute",
                visibility: "hidden",
                whiteSpace: "pre",
                fontFamily: $input.css("font-family"),
                fontSize: $input.css("font-size"),
                fontStyle: $input.css("font-style"),
                fontVariant: $input.css("font-variant"),
                fontWeight: $input.css("font-weight"),
                wordSpacing: $input.css("word-spacing"),
                letterSpacing: $input.css("letter-spacing"),
                textIndent: $input.css("text-indent"),
                textRendering: $input.css("text-rendering"),
                textTransform: $input.css("text-transform")
            }).insertAfter($input);
        }
        function areQueriesEquivalent(a, b) {
            return Input.normalizeQuery(a) === Input.normalizeQuery(b);
        }
        function withModifier($e) {
            return $e.altKey || $e.ctrlKey || $e.metaKey || $e.shiftKey;
        }
    }();
    var Dataset = function() {
        "use strict";
        var datasetKey = "ttDataset", valueKey = "ttValue", datumKey = "ttDatum";
        function Dataset(o) {
            o = o || {};
            o.templates = o.templates || {};
            if (!o.source) {
                $.error("missing source");
            }
            if (o.name && !isValidName(o.name)) {
                $.error("invalid dataset name: " + o.name);
            }
            this.query = null;
            this.highlight = !!o.highlight;
            this.name = o.name || _.getUniqueId();
            this.source = o.source;
            this.displayFn = getDisplayFn(o.display || o.displayKey);
            this.templates = getTemplates(o.templates, this.displayFn);
            this.$el = $(html.dataset.replace("%CLASS%", this.name));
        }
        Dataset.extractDatasetName = function extractDatasetName(el) {
            return $(el).data(datasetKey);
        };
        Dataset.extractValue = function extractDatum(el) {
            return $(el).data(valueKey);
        };
        Dataset.extractDatum = function extractDatum(el) {
            return $(el).data(datumKey);
        };
        _.mixin(Dataset.prototype, EventEmitter, {
            _render: function render(query, suggestions) {
                if (!this.$el) {
                    return;
                }
                var that = this, hasSuggestions;
                this.$el.empty();
                hasSuggestions = suggestions && suggestions.length;
                if (!hasSuggestions && this.templates.empty) {
                    this.$el.html(getEmptyHtml()).prepend(that.templates.header ? getHeaderHtml() : null).append(that.templates.footer ? getFooterHtml() : null);
                } else if (hasSuggestions) {
                    this.$el.html(getSuggestionsHtml()).prepend(that.templates.header ? getHeaderHtml() : null).append(that.templates.footer ? getFooterHtml() : null);
                }
                this.trigger("rendered");
                function getEmptyHtml() {
                    return that.templates.empty({
                        query: query,
                        isEmpty: true
                    });
                }
                function getSuggestionsHtml() {
                    var $suggestions, nodes;
                    $suggestions = $(html.suggestions).css(css.suggestions);
                    nodes = _.map(suggestions, getSuggestionNode);
                    $suggestions.append.apply($suggestions, nodes);
                    that.highlight && highlight({
                        className: "tt-highlight",
                        node: $suggestions[0],
                        pattern: query
                    });
                    return $suggestions;
                    function getSuggestionNode(suggestion) {
                        var $el;
                        $el = $(html.suggestion).append(that.templates.suggestion(suggestion)).data(datasetKey, that.name).data(valueKey, that.displayFn(suggestion)).data(datumKey, suggestion);
                        $el.children().each(function() {
                            $(this).css(css.suggestionChild);
                        });
                        return $el;
                    }
                }
                function getHeaderHtml() {
                    return that.templates.header({
                        query: query,
                        isEmpty: !hasSuggestions
                    });
                }
                function getFooterHtml() {
                    return that.templates.footer({
                        query: query,
                        isEmpty: !hasSuggestions
                    });
                }
            },
            getRoot: function getRoot() {
                return this.$el;
            },
            update: function update(query) {
                var that = this;
                this.query = query;
                this.canceled = false;
                this.source(query, render);
                function render(suggestions) {
                    if (!that.canceled && query === that.query) {
                        that._render(query, suggestions);
                    }
                }
            },
            cancel: function cancel() {
                this.canceled = true;
            },
            clear: function clear() {
                this.cancel();
                this.$el.empty();
                this.trigger("rendered");
            },
            isEmpty: function isEmpty() {
                return this.$el.is(":empty");
            },
            destroy: function destroy() {
                this.$el = null;
            }
        });
        return Dataset;
        function getDisplayFn(display) {
            display = display || "value";
            return _.isFunction(display) ? display : displayFn;
            function displayFn(obj) {
                return obj[display];
            }
        }
        function getTemplates(templates, displayFn) {
            return {
                empty: templates.empty && _.templatify(templates.empty),
                header: templates.header && _.templatify(templates.header),
                footer: templates.footer && _.templatify(templates.footer),
                suggestion: templates.suggestion || suggestionTemplate
            };
            function suggestionTemplate(context) {
                return "<p>" + displayFn(context) + "</p>";
            }
        }
        function isValidName(str) {
            return /^[_a-zA-Z0-9-]+$/.test(str);
        }
    }();
    var Dropdown = function() {
        "use strict";
        function Dropdown(o) {
            var that = this, onSuggestionClick, onSuggestionMouseEnter, onSuggestionMouseLeave;
            o = o || {};
            if (!o.menu) {
                $.error("menu is required");
            }
            this.isOpen = false;
            this.isEmpty = true;
            this.datasets = _.map(o.datasets, initializeDataset);
            onSuggestionClick = _.bind(this._onSuggestionClick, this);
            onSuggestionMouseEnter = _.bind(this._onSuggestionMouseEnter, this);
            onSuggestionMouseLeave = _.bind(this._onSuggestionMouseLeave, this);
            this.$menu = $(o.menu).on("click.tt", ".tt-suggestion", onSuggestionClick).on("mouseenter.tt", ".tt-suggestion", onSuggestionMouseEnter).on("mouseleave.tt", ".tt-suggestion", onSuggestionMouseLeave);
            _.each(this.datasets, function(dataset) {
                that.$menu.append(dataset.getRoot());
                dataset.onSync("rendered", that._onRendered, that);
            });
        }
        _.mixin(Dropdown.prototype, EventEmitter, {
            _onSuggestionClick: function onSuggestionClick($e) {
                this.trigger("suggestionClicked", $($e.currentTarget));
            },
            _onSuggestionMouseEnter: function onSuggestionMouseEnter($e) {
                this._removeCursor();
                this._setCursor($($e.currentTarget), true);
            },
            _onSuggestionMouseLeave: function onSuggestionMouseLeave() {
                this._removeCursor();
            },
            _onRendered: function onRendered() {
                this.isEmpty = _.every(this.datasets, isDatasetEmpty);
                this.isEmpty ? this._hide() : this.isOpen && this._show();
                this.trigger("datasetRendered");
                function isDatasetEmpty(dataset) {
                    return dataset.isEmpty();
                }
            },
            _hide: function() {
                this.$menu.hide();
            },
            _show: function() {
                this.$menu.css("display", "block");
            },
            _getSuggestions: function getSuggestions() {
                return this.$menu.find(".tt-suggestion");
            },
            _getCursor: function getCursor() {
                return this.$menu.find(".tt-cursor").first();
            },
            _setCursor: function setCursor($el, silent) {
                $el.first().addClass("tt-cursor");
                !silent && this.trigger("cursorMoved");
            },
            _removeCursor: function removeCursor() {
                this._getCursor().removeClass("tt-cursor");
            },
            _moveCursor: function moveCursor(increment) {
                var $suggestions, $oldCursor, newCursorIndex, $newCursor;
                if (!this.isOpen) {
                    return;
                }
                $oldCursor = this._getCursor();
                $suggestions = this._getSuggestions();
                this._removeCursor();
                newCursorIndex = $suggestions.index($oldCursor) + increment;
                newCursorIndex = (newCursorIndex + 1) % ($suggestions.length + 1) - 1;
                if (newCursorIndex === -1) {
                    this.trigger("cursorRemoved");
                    return;
                } else if (newCursorIndex < -1) {
                    newCursorIndex = $suggestions.length - 1;
                }
                this._setCursor($newCursor = $suggestions.eq(newCursorIndex));
                this._ensureVisible($newCursor);
            },
            _ensureVisible: function ensureVisible($el) {
                var elTop, elBottom, menuScrollTop, menuHeight;
                elTop = $el.position().top;
                elBottom = elTop + $el.outerHeight(true);
                menuScrollTop = this.$menu.scrollTop();
                menuHeight = this.$menu.height() + parseInt(this.$menu.css("paddingTop"), 10) + parseInt(this.$menu.css("paddingBottom"), 10);
                if (elTop < 0) {
                    this.$menu.scrollTop(menuScrollTop + elTop);
                } else if (menuHeight < elBottom) {
                    this.$menu.scrollTop(menuScrollTop + (elBottom - menuHeight));
                }
            },
            close: function close() {
                if (this.isOpen) {
                    this.isOpen = false;
                    this._removeCursor();
                    this._hide();
                    this.trigger("closed");
                }
            },
            open: function open() {
                if (!this.isOpen) {
                    this.isOpen = true;
                    !this.isEmpty && this._show();
                    this.trigger("opened");
                }
            },
            setLanguageDirection: function setLanguageDirection(dir) {
                this.$menu.css(dir === "ltr" ? css.ltr : css.rtl);
            },
            moveCursorUp: function moveCursorUp() {
                this._moveCursor(-1);
            },
            moveCursorDown: function moveCursorDown() {
                this._moveCursor(+1);
            },
            getDatumForSuggestion: function getDatumForSuggestion($el) {
                var datum = null;
                if ($el.length) {
                    datum = {
                        raw: Dataset.extractDatum($el),
                        value: Dataset.extractValue($el),
                        datasetName: Dataset.extractDatasetName($el)
                    };
                }
                return datum;
            },
            getDatumForCursor: function getDatumForCursor() {
                return this.getDatumForSuggestion(this._getCursor().first());
            },
            getDatumForTopSuggestion: function getDatumForTopSuggestion() {
                return this.getDatumForSuggestion(this._getSuggestions().first());
            },
            update: function update(query) {
                _.each(this.datasets, updateDataset);
                function updateDataset(dataset) {
                    dataset.update(query);
                }
            },
            empty: function empty() {
                _.each(this.datasets, clearDataset);
                this.isEmpty = true;
                function clearDataset(dataset) {
                    dataset.clear();
                }
            },
            isVisible: function isVisible() {
                return this.isOpen && !this.isEmpty;
            },
            destroy: function destroy() {
                this.$menu.off(".tt");
                this.$menu = null;
                _.each(this.datasets, destroyDataset);
                function destroyDataset(dataset) {
                    dataset.destroy();
                }
            }
        });
        return Dropdown;
        function initializeDataset(oDataset) {
            return new Dataset(oDataset);
        }
    }();
    var Typeahead = function() {
        "use strict";
        var attrsKey = "ttAttrs";
        function Typeahead(o) {
            var $menu, $input, $hint;
            o = o || {};
            if (!o.input) {
                $.error("missing input");
            }
            this.isActivated = false;
            this.autoselect = !!o.autoselect;
            this.minLength = _.isNumber(o.minLength) ? o.minLength : 1;
            this.$node = buildDom(o.input, o.withHint);
            $menu = this.$node.find(".tt-dropdown-menu");
            $input = this.$node.find(".tt-input");
            $hint = this.$node.find(".tt-hint");
            $input.on("blur.tt", function($e) {
                var active, isActive, hasActive;
                active = document.activeElement;
                isActive = $menu.is(active);
                hasActive = $menu.has(active).length > 0;
                if (_.isMsie() && (isActive || hasActive)) {
                    $e.preventDefault();
                    $e.stopImmediatePropagation();
                    _.defer(function() {
                        $input.focus();
                    });
                }
            });
            $menu.on("mousedown.tt", function($e) {
                $e.preventDefault();
            });
            this.eventBus = o.eventBus || new EventBus({
                el: $input
            });
            this.dropdown = new Dropdown({
                menu: $menu,
                datasets: o.datasets
            }).onSync("suggestionClicked", this._onSuggestionClicked, this).onSync("cursorMoved", this._onCursorMoved, this).onSync("cursorRemoved", this._onCursorRemoved, this).onSync("opened", this._onOpened, this).onSync("closed", this._onClosed, this).onAsync("datasetRendered", this._onDatasetRendered, this);
            this.input = new Input({
                input: $input,
                hint: $hint
            }).onSync("focused", this._onFocused, this).onSync("blurred", this._onBlurred, this).onSync("enterKeyed", this._onEnterKeyed, this).onSync("tabKeyed", this._onTabKeyed, this).onSync("escKeyed", this._onEscKeyed, this).onSync("upKeyed", this._onUpKeyed, this).onSync("downKeyed", this._onDownKeyed, this).onSync("leftKeyed", this._onLeftKeyed, this).onSync("rightKeyed", this._onRightKeyed, this).onSync("queryChanged", this._onQueryChanged, this).onSync("whitespaceChanged", this._onWhitespaceChanged, this);
            this._setLanguageDirection();
        }
        _.mixin(Typeahead.prototype, {
            _onSuggestionClicked: function onSuggestionClicked(type, $el) {
                var datum;
                if (datum = this.dropdown.getDatumForSuggestion($el)) {
                    this._select(datum);
                }
            },
            _onCursorMoved: function onCursorMoved() {
                var datum = this.dropdown.getDatumForCursor();
                this.input.setInputValue(datum.value, true);
                this.eventBus.trigger("cursorchanged", datum.raw, datum.datasetName);
            },
            _onCursorRemoved: function onCursorRemoved() {
                this.input.resetInputValue();
                this._updateHint();
            },
            _onDatasetRendered: function onDatasetRendered() {
                this._updateHint();
            },
            _onOpened: function onOpened() {
                this._updateHint();
                this.eventBus.trigger("opened");
            },
            _onClosed: function onClosed() {
                this.input.clearHint();
                this.eventBus.trigger("closed");
            },
            _onFocused: function onFocused() {
                this.isActivated = true;
                this.dropdown.open();
            },
            _onBlurred: function onBlurred() {
                this.isActivated = false;
                this.dropdown.empty();
                this.dropdown.close();
            },
            _onEnterKeyed: function onEnterKeyed(type, $e) {
                var cursorDatum, topSuggestionDatum;
                cursorDatum = this.dropdown.getDatumForCursor();
                topSuggestionDatum = this.dropdown.getDatumForTopSuggestion();
                if (cursorDatum) {
                    this._select(cursorDatum);
                    $e.preventDefault();
                } else if (this.autoselect && topSuggestionDatum) {
                    this._select(topSuggestionDatum);
                    $e.preventDefault();
                }
            },
            _onTabKeyed: function onTabKeyed(type, $e) {
                var datum;
                if (datum = this.dropdown.getDatumForCursor()) {
                    this._select(datum);
                    $e.preventDefault();
                } else {
                    this._autocomplete(true);
                }
            },
            _onEscKeyed: function onEscKeyed() {
                this.dropdown.close();
                this.input.resetInputValue();
            },
            _onUpKeyed: function onUpKeyed() {
                var query = this.input.getQuery();
                this.dropdown.isEmpty && query.length >= this.minLength ? this.dropdown.update(query) : this.dropdown.moveCursorUp();
                this.dropdown.open();
            },
            _onDownKeyed: function onDownKeyed() {
                var query = this.input.getQuery();
                this.dropdown.isEmpty && query.length >= this.minLength ? this.dropdown.update(query) : this.dropdown.moveCursorDown();
                this.dropdown.open();
            },
            _onLeftKeyed: function onLeftKeyed() {
                this.dir === "rtl" && this._autocomplete();
            },
            _onRightKeyed: function onRightKeyed() {
                this.dir === "ltr" && this._autocomplete();
            },
            _onQueryChanged: function onQueryChanged(e, query) {
                this.input.clearHintIfInvalid();
                query.length >= this.minLength ? this.dropdown.update(query) : this.dropdown.empty();
                this.dropdown.open();
                this._setLanguageDirection();
            },
            _onWhitespaceChanged: function onWhitespaceChanged() {
                this._updateHint();
                this.dropdown.open();
            },
            _setLanguageDirection: function setLanguageDirection() {
                var dir;
                if (this.dir !== (dir = this.input.getLanguageDirection())) {
                    this.dir = dir;
                    this.$node.css("direction", dir);
                    this.dropdown.setLanguageDirection(dir);
                }
            },
            _updateHint: function updateHint() {
                var datum, val, query, escapedQuery, frontMatchRegEx, match;
                datum = this.dropdown.getDatumForTopSuggestion();
                if (datum && this.dropdown.isVisible() && !this.input.hasOverflow()) {
                    val = this.input.getInputValue();
                    query = Input.normalizeQuery(val);
                    escapedQuery = _.escapeRegExChars(query);
                    frontMatchRegEx = new RegExp("^(?:" + escapedQuery + ")(.+$)", "i");
                    match = frontMatchRegEx.exec(datum.value);
                    match ? this.input.setHint(val + match[1]) : this.input.clearHint();
                } else {
                    this.input.clearHint();
                }
            },
            _autocomplete: function autocomplete(laxCursor) {
                var hint, query, isCursorAtEnd, datum;
                hint = this.input.getHint();
                query = this.input.getQuery();
                isCursorAtEnd = laxCursor || this.input.isCursorAtEnd();
                if (hint && query !== hint && isCursorAtEnd) {
                    datum = this.dropdown.getDatumForTopSuggestion();
                    datum && this.input.setInputValue(datum.value);
                    this.eventBus.trigger("autocompleted", datum.raw, datum.datasetName);
                }
            },
            _select: function select(datum) {
                this.input.setQuery(datum.value);
                this.input.setInputValue(datum.value, true);
                this._setLanguageDirection();
                this.eventBus.trigger("selected", datum.raw, datum.datasetName);
                this.dropdown.close();
                _.defer(_.bind(this.dropdown.empty, this.dropdown));
            },
            open: function open() {
                this.dropdown.open();
            },
            close: function close() {
                this.dropdown.close();
            },
            setVal: function setVal(val) {
                val = _.toStr(val);
                if (this.isActivated) {
                    this.input.setInputValue(val);
                } else {
                    this.input.setQuery(val);
                    this.input.setInputValue(val, true);
                }
                this._setLanguageDirection();
            },
            getVal: function getVal() {
                return this.input.getQuery();
            },
            destroy: function destroy() {
                this.input.destroy();
                this.dropdown.destroy();
                destroyDomStructure(this.$node);
                this.$node = null;
            }
        });
        return Typeahead;
        function buildDom(input, withHint) {
            var $input, $wrapper, $dropdown, $hint;
            $input = $(input);
            $wrapper = $(html.wrapper).css(css.wrapper);
            $dropdown = $(html.dropdown).css(css.dropdown);
            $hint = $input.clone().css(css.hint).css(getBackgroundStyles($input));
            $hint.val("").removeData().addClass("tt-hint").removeAttr("id name placeholder required").prop("readonly", true).attr({
                autocomplete: "off",
                spellcheck: "false",
                tabindex: -1
            });
            $input.data(attrsKey, {
                dir: $input.attr("dir"),
                autocomplete: $input.attr("autocomplete"),
                spellcheck: $input.attr("spellcheck"),
                style: $input.attr("style")
            });
            $input.addClass("tt-input").attr({
                autocomplete: "off",
                spellcheck: false
            }).css(withHint ? css.input : css.inputWithNoHint);
            try {
                !$input.attr("dir") && $input.attr("dir", "auto");
            } catch (e) {}
            return $input.wrap($wrapper).parent().prepend(withHint ? $hint : null).append($dropdown);
        }
        function getBackgroundStyles($el) {
            return {
                backgroundAttachment: $el.css("background-attachment"),
                backgroundClip: $el.css("background-clip"),
                backgroundColor: $el.css("background-color"),
                backgroundImage: $el.css("background-image"),
                backgroundOrigin: $el.css("background-origin"),
                backgroundPosition: $el.css("background-position"),
                backgroundRepeat: $el.css("background-repeat"),
                backgroundSize: $el.css("background-size")
            };
        }
        function destroyDomStructure($node) {
            var $input = $node.find(".tt-input");
            _.each($input.data(attrsKey), function(val, key) {
                _.isUndefined(val) ? $input.removeAttr(key) : $input.attr(key, val);
            });
            $input.detach().removeData(attrsKey).removeClass("tt-input").insertAfter($node);
            $node.remove();
        }
    }();
    (function() {
        "use strict";
        var old, typeaheadKey, methods;
        old = $.fn.typeahead;
        typeaheadKey = "ttTypeahead";
        methods = {
            initialize: function initialize(o, datasets) {
                datasets = _.isArray(datasets) ? datasets : [].slice.call(arguments, 1);
                o = o || {};
                return this.each(attach);
                function attach() {
                    var $input = $(this), eventBus, typeahead;
                    _.each(datasets, function(d) {
                        d.highlight = !!o.highlight;
                    });
                    typeahead = new Typeahead({
                        input: $input,
                        eventBus: eventBus = new EventBus({
                            el: $input
                        }),
                        withHint: _.isUndefined(o.hint) ? true : !!o.hint,
                        minLength: o.minLength,
                        autoselect: o.autoselect,
                        datasets: datasets
                    });
                    $input.data(typeaheadKey, typeahead);
                }
            },
            open: function open() {
                return this.each(openTypeahead);
                function openTypeahead() {
                    var $input = $(this), typeahead;
                    if (typeahead = $input.data(typeaheadKey)) {
                        typeahead.open();
                    }
                }
            },
            close: function close() {
                return this.each(closeTypeahead);
                function closeTypeahead() {
                    var $input = $(this), typeahead;
                    if (typeahead = $input.data(typeaheadKey)) {
                        typeahead.close();
                    }
                }
            },
            val: function val(newVal) {
                return !arguments.length ? getVal(this.first()) : this.each(setVal);
                function setVal() {
                    var $input = $(this), typeahead;
                    if (typeahead = $input.data(typeaheadKey)) {
                        typeahead.setVal(newVal);
                    }
                }
                function getVal($input) {
                    var typeahead, query;
                    if (typeahead = $input.data(typeaheadKey)) {
                        query = typeahead.getVal();
                    }
                    return query;
                }
            },
            destroy: function destroy() {
                return this.each(unattach);
                function unattach() {
                    var $input = $(this), typeahead;
                    if (typeahead = $input.data(typeaheadKey)) {
                        typeahead.destroy();
                        $input.removeData(typeaheadKey);
                    }
                }
            }
        };
        $.fn.typeahead = function(method) {
            var tts;
            if (methods[method] && method !== "initialize") {
                tts = this.filter(function() {
                    return !!$(this).data(typeaheadKey);
                });
                return methods[method].apply(tts, [].slice.call(arguments, 1));
            } else {
                return methods.initialize.apply(this, arguments);
            }
        };
        $.fn.typeahead.noConflict = function noConflict() {
            $.fn.typeahead = old;
            return this;
        };
    })();
})(window.jQuery);
this._last = function(array) {
  return array[array.length - 1];
};

this._first = function(array) {
  return array[0];
};

this._firstNonEmptyValue = function(o) {
  var k, v;
  for (k in o) {
    v = o[k];
    if (k[0] !== '_' && v && v !== '') {
      return v;
    }
  }
  return null;
};

this._entityMap = {
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  '"': '&quot;',
  "'": '&#39;',
  "/": '&#x2F;'
};

this._escapeHtml = function(string) {
  return String(string).replace(/[&<>"'\/]/g, function(s) {
    return _entityMap[s];
  });
};

if (typeof String.prototype.titleize !== 'function') {
  String.prototype.titleize = function() {
    return this.replace(/_/g, ' ').replace(/\b./g, (function(m) {
      return m.toUpperCase();
    }));
  };
}

if (typeof String.prototype.reverse !== 'function') {
  String.prototype.reverse = function() {
    return this.split("").reverse().join("");
  };
}

if (typeof String.prototype.startsWith !== 'function') {
  String.prototype.startsWith = function(str) {
    return this.slice(0, str.length) === str;
  };
}

if (typeof String.prototype.endsWith !== 'function') {
  String.prototype.endsWith = function(str) {
    return this.slice(this.length - str.length, this.length) === str;
  };
}

if (typeof String.prototype.plainText !== 'function') {
  String.prototype.plainText = function() {
    return $("<div>" + this + "</div>").text();
  };
}

this.extend = function(obj, mixin) {
  var method, name;
  for (name in mixin) {
    method = mixin[name];
    obj[name] = method;
  }
  return obj;
};

this.include = function(klass, mixin) {
  return extend(klass.prototype, mixin);
};

this.Chr = (function() {
  function Chr() {
    this.formInputs = {};
    this.modules = {};
    this.itemsPerPageRequest = Math.ceil($(window).height() / 60) * 2;
  }

  Chr.prototype._unset_active_menu_items = function() {
    return $('.sidebar .menu a.active').removeClass('active');
  };

  Chr.prototype._set_active_menu_item = function() {
    var a, currentModuleName, i, len, moduleName, ref;
    currentModuleName = window.location.hash.split('/')[1];
    ref = this.$mainMenu.children();
    for (i = 0, len = ref.length; i < len; i++) {
      a = ref[i];
      moduleName = $(a).attr('href').split('/')[1];
      if (currentModuleName === moduleName) {
        return $(a).addClass('active');
      }
    }
  };

  Chr.prototype._navigate = function(path) {
    var config, crumb, crumbs, i, len, objectId, ref;
    crumbs = path.split('/');
    if (this.module !== this.modules[crumbs[1]]) {
      if ((ref = this.module) != null) {
        ref.hide();
      }
    }
    this.module = this.modules[crumbs[1]];
    if (this.module) {
      this.module.show();
      config = this.module.config;
      crumbs = crumbs.splice(2);
      if (crumbs.length > 0) {
        for (i = 0, len = crumbs.length; i < len; i++) {
          crumb = crumbs[i];
          if (crumb === 'new') {
            return this.module.showView(null, config, 'New');
          }
          if (crumb === 'view') {
            objectId = _last(crumbs);
            return this.module.showViewByObjectId(objectId, config);
          }
          config = config.items[crumb];
          if (config.objectStore) {
            return this.module.showViewByObjectId('', config, crumb.titleize());
          } else {
            this.module.showNestedList(crumb);
          }
        }
      } else {
        return this.module.showRootList();
      }
    }
  };

  Chr.prototype.unsetActiveListItems = function() {
    return $('.list .items .item.active').removeClass('active');
  };

  Chr.prototype.isMobile = function() {
    return $(window).width() < 760;
  };

  Chr.prototype.updateHash = function(hash, skipHashChange) {
    if (skipHashChange == null) {
      skipHashChange = false;
    }
    window._skipHashchange = skipHashChange;
    return location.hash = hash;
  };

  Chr.prototype.start = function(config1) {
    var config, name, ref, ref1;
    this.config = config1;
    this.$el = $((ref = this.config.selector) != null ? ref : 'body');
    this.$navBar = $("<nav class='sidebar'>");
    this.$mainMenu = $("<div class='menu'>");
    this.$navBar.append(this.$mainMenu);
    this.$el.append(this.$navBar);
    ref1 = this.config.modules;
    for (name in ref1) {
      config = ref1[name];
      this.modules[name] = new Module(this, name, config);
    }
    $(this).on('hashchange', (function(_this) {
      return function() {
        return _this._set_active_menu_item();
      };
    })(this));
    window.onhashchange = (function(_this) {
      return function() {
        _this._unset_active_menu_items();
        _this.unsetActiveListItems();
        if (!window._skipHashchange) {
          _this._navigate(location.hash);
        }
        window._skipHashchange = false;
        return $(_this).trigger('hashchange');
      };
    })(this);
    $(document).on('click', 'a.silent', function(e) {
      return window._skipHashchange = true;
    });
    window._skipHashchange = false;
    if (location.hash !== '') {
      this._navigate(location.hash);
      return $(this).trigger('hashchange');
    } else if (!this.isMobile()) {
      return location.hash = '#/' + Object.keys(this.modules)[0];
    }
  };

  Chr.prototype.addMenuItem = function(moduleName, title) {
    return this.$mainMenu.append("<a href='#/" + moduleName + "'>" + title + "</a>");
  };

  Chr.prototype.showAlert = function(message) {
    return console.log('Alert: ' + message);
  };

  Chr.prototype.showError = function(message) {
    return alert('Error: ' + message);
  };

  return Chr;

})();

window.chr = new Chr();

this.Module = (function() {
  function Module(chr1, name, config1) {
    var base, firstNestedList, menuPath, menuTitle, ref;
    this.chr = chr1;
    this.name = name;
    this.config = config1;
    this.nestedLists = {};
    this.$el = $("<section class='module " + this.name + "' style='display: none;'>");
    this.chr.$el.append(this.$el);
    this.activeList = this.rootList = new List(this, this.name, this.config);
    menuTitle = (ref = this.config.menuTitle) != null ? ref : this.config.title;
    if (menuTitle == null) {
      menuTitle = this.name.titleize();
    }
    menuPath = this.name;
    if (this.config.showNestedListsAside) {
      this.$el.addClass('first-list-aside');
      firstNestedList = _firstNonEmptyValue(this.nestedLists);
      if (!this.chr.isMobile() && firstNestedList) {
        menuPath += "/" + firstNestedList.name;
      }
    }
    this.chr.addMenuItem(menuPath, menuTitle);
    if (typeof (base = this.config).onModuleInit === "function") {
      base.onModuleInit(this);
    }
  }

  Module.prototype._update_active_list_items = function() {
    if (!this.activeList.isVisible()) {
      return this.activeList.updateItems();
    }
  };

  Module.prototype._view_path = function() {
    var currentList, ref;
    currentList = (ref = this.visibleNestedListShownWithParent()) != null ? ref : this.activeList;
    return currentList.path;
  };

  Module.prototype.addNestedList = function(listName, config, parentList) {
    return this.nestedLists[listName] = new List(this, listName, config, parentList);
  };

  Module.prototype.showNestedList = function(listName) {
    var listToShow;
    listToShow = this.nestedLists[listName];
    if (listToShow.showWithParent) {
      listToShow.updateItems();
      listToShow.show((function(_this) {
        return function() {
          var exceptList;
          return _this.hideNestedLists(exceptList = listName);
        };
      })(this));
    } else {
      this.activeList = listToShow;
      this._update_active_list_items();
      this.activeList.show();
    }
    return this.destroyView();
  };

  Module.prototype.hideNestedLists = function(exceptList) {
    var key, list, ref, results;
    this.activeList = this.rootList;
    ref = this.nestedLists;
    results = [];
    for (key in ref) {
      list = ref[key];
      if (key !== exceptList) {
        results.push(list.hide());
      }
    }
    return results;
  };

  Module.prototype.visibleNestedListShownWithParent = function() {
    var key, list, ref;
    ref = this.nestedLists;
    for (key in ref) {
      list = ref[key];
      if (list.isVisible() && list.showWithParent) {
        return list;
      }
    }
  };

  Module.prototype.showRootList = function() {
    var results;
    this.destroyView();
    results = [];
    while (this.activeList !== this.rootList) {
      results.push(this.hideActiveList());
    }
    return results;
  };

  Module.prototype.hideActiveList = function() {
    this.activeList.$el.hide();
    return this.activeList = this.activeList.parentList;
  };

  Module.prototype.showView = function(object, config, title) {
    var newView;
    newView = new View(this, config, this._view_path(), object, title);
    this.chr.$el.append(newView.$el);
    return newView.show((function(_this) {
      return function() {
        _this.destroyView();
        return _this.view = newView;
      };
    })(this));
  };

  Module.prototype.showViewByObjectId = function(objectId, config, title) {
    var onError, onSuccess;
    onSuccess = (function(_this) {
      return function(object) {
        return _this.showView(object, config, title);
      };
    })(this);
    onError = function() {
      return chr.showError("can\'t show view for requested object");
    };
    if (objectId === '') {
      return config.objectStore.loadObject({
        onSuccess: onSuccess,
        onError: onError
      });
    } else {
      return config.arrayStore.loadObject(objectId, {
        onSuccess: onSuccess,
        onError: onError
      });
    }
  };

  Module.prototype.destroyView = function() {
    var ref;
    return (ref = this.view) != null ? ref.destroy() : void 0;
  };

  Module.prototype.show = function() {
    this._update_active_list_items();
    this.$el.show();
    return this.activeList.show();
  };

  Module.prototype.hide = function() {
    this.hideNestedLists();
    this.destroyView();
    return this.$el.hide();
  };

  return Module;

})();

this.listConfig = {
  _process_config_items: function() {
    var config, object, ref, ref1, results, slug;
    ref = this.config.items;
    results = [];
    for (slug in ref) {
      config = ref[slug];
      object = {
        _id: slug,
        _title: (ref1 = config.title) != null ? ref1 : slug.titleize()
      };
      if (config.items || config.arrayStore) {
        this.module.addNestedList(slug, config, this);
      }
      this._add_item("#/" + this.path + "/" + slug, object, 0, config);
      results.push(this.configItemsCount += 1);
    }
    return results;
  },
  _bind_config_array_store: function() {
    this.config.arrayStore.on('object_added', (function(_this) {
      return function(e, data) {
        return _this._add_item("#/" + _this.path + "/view/" + data.object._id, data.object, data.position, _this.config);
      };
    })(this));
    if (this.config.objects) {
      this.config.arrayStore.addObjects(this.config.objects);
    }
    this.config.arrayStore.on('object_changed', (function(_this) {
      return function(e, data) {
        var item;
        item = _this.items[data.object._id];
        if (item) {
          item.render();
          return _this._update_item_position(item, data.position);
        }
      };
    })(this));
    this.config.arrayStore.on('object_removed', (function(_this) {
      return function(e, data) {
        var item;
        item = _this.items[data.object_id];
        if (item) {
          item.destroy();
          return delete _this.items[data.object_id];
        }
      };
    })(this));
    this.config.arrayStore.on('objects_added', (function(_this) {
      return function(e, data) {
        _this._hide_spinner();
        return _this._set_active_item();
      };
    })(this));
    if (this.config.arrayStore.pagination) {
      this._bind_pagination();
    }
    if (this.config.arrayStore.searchable) {
      this._bind_search();
    }
    if (this.config.arrayStore.reorderable) {
      return this._bind_reorder();
    }
  },
  _bind_config_object_store: function() {}
};

this.listPagination = {
  _bind_pagination: function() {
    this.lastScrollTop = 0;
    return this.$items.scroll((function(_this) {
      return function(e) {
        var listItemsHeight, listViewHeight;
        if (_this.lastScrollTop < e.target.scrollTop) {
          if (!_this.config.arrayStore.dataFetchLock) {
            listViewHeight = _this.$el.height();
            listItemsHeight = 0;
            _this.$items.children().each(function() {
              return listItemsHeight += $(this).height();
            });
            if (listItemsHeight < (listViewHeight + e.target.scrollTop + 100)) {
              if (!_this.config.arrayStore.lastPageLoaded) {
                _this._show_spinner();
                _this.config.arrayStore.load(false, {
                  onSuccess: function() {},
                  onError: function() {
                    return chr.showAlert("Can't load next page, server error 500.");
                  }
                });
              }
            }
          }
        }
        return _this.lastScrollTop = e.target.scrollTop;
      };
    })(this));
  }
};

this.listReorder = {
  _bind_reorder: function() {
    var _getObjectNewPosition, arrayStore, config, items, list;
    items = this.items;
    list = this.$items.get(0);
    arrayStore = this.config.arrayStore;
    config = arrayStore.reorderable;
    _getObjectNewPosition = function(el) {
      var $el, newPosition, nextObjectId, nextObjectPosition, prevObjectId, prevObjectPosition;
      $el = $(el);
      nextObjectId = $el.next().attr('data-id');
      prevObjectId = $el.prev().attr('data-id');
      nextObjectPosition = 0;
      prevObjectPosition = 0;
      if (prevObjectId) {
        prevObjectPosition = items[prevObjectId].position();
      }
      if (nextObjectId) {
        nextObjectPosition = items[nextObjectId].position();
      }
      if (arrayStore.sortReverse) {
        newPosition = nextObjectPosition + Math.abs(nextObjectPosition - prevObjectPosition) / 2.0;
      } else {
        newPosition = prevObjectPosition + Math.abs(nextObjectPosition - prevObjectPosition) / 2.0;
      }
      return newPosition;
    };
    new Slip(list);
    list.addEventListener('slip:beforeswipe', function(e) {
      return e.preventDefault();
    });
    list.addEventListener('slip:beforewait', (function(e) {
      if ($(e.target).hasClass("icon-reorder")) {
        return e.preventDefault();
      }
    }), false);
    list.addEventListener('slip:beforereorder', (function(e) {
      if (!$(e.target).hasClass("icon-reorder")) {
        return e.preventDefault();
      }
    }), false);
    list.addEventListener('slip:reorder', ((function(_this) {
      return function(e) {
        var objectId, objectPositionValue, value;
        e.target.parentNode.insertBefore(e.target, e.detail.insertBefore);
        objectPositionValue = _getObjectNewPosition(e.target);
        objectId = $(e.target).attr('data-id');
        value = {};
        value["[" + arrayStore.sortBy] = "" + objectPositionValue;
        arrayStore.update(objectId, value, {
          onSuccess: function(object) {},
          onError: function(errors) {}
        });
        return false;
      };
    })(this)), false);
    return $(list).addClass('reorderable');
  }
};

this.listSearch = {
  _bind_search: function() {
    this.$search = $("<div class='search'></div>");
    this.$searchIcon = $("<a href='#' class='icon'></a>");
    this.$searchInput = $("<input type='text' placeholder='Search...' />");
    this.$searchCancel = $("<a href='#' class='cancel'>Cancel</a>");
    this.$header.append(this.$search);
    this.$search.append(this.$searchIcon);
    this.$search.append(this.$searchInput);
    this.$search.append(this.$searchCancel);
    this.$searchInput.on('keyup', (function(_this) {
      return function(e) {
        if (e.keyCode === 27) {
          return _this._on_search_cancel();
        }
        if (e.keyCode === 13) {
          return _this._on_search();
        }
      };
    })(this));
    this.$searchIcon.on('click', (function(_this) {
      return function(e) {
        e.preventDefault();
        return _this._on_search_show();
      };
    })(this));
    return this.$searchCancel.on('click', (function(_this) {
      return function(e) {
        e.preventDefault();
        return _this._on_search_cancel();
      };
    })(this));
  },
  _on_search: function() {
    var query;
    query = this.$searchInput.val();
    this._show_spinner();
    return this.config.arrayStore.search(query);
  },
  _on_search_show: function() {
    this.$el.addClass('list-search');
    this.$searchInput.focus();
    return this.$search.show();
  },
  _on_search_cancel: function() {
    this.$el.removeClass('list-search');
    this.$searchInput.val('');
    this._show_spinner();
    return this.config.arrayStore.reset();
  }
};

this.List = (function() {
  function List(module, name, config1, parentList) {
    var base, ref, ref1, ref2;
    this.module = module;
    this.name = name;
    this.config = config1;
    this.parentList = parentList;
    this.configItemsCount = 0;
    this.path = this._path();
    this.items = {};
    this.title = (ref = this.config.title) != null ? ref : this.name.titleize();
    this.itemClass = (ref1 = this.config.itemClass) != null ? ref1 : Item;
    this.showWithParent = false;
    if (this.parentList) {
      this.showWithParent = this.parentList.config.showNestedListsAside || false;
    }
        if ((ref2 = this.config.showListWithParent) != null) {
      ref2;
    } else {
      false;
    };
    this.$el = $("<div class='list " + this.name + "'>");
    this.module.$el.append(this.$el);
    if (this.parentList) {
      this.$el.hide();
    }
    this.$items = $("<div class='items'>");
    this.$el.append(this.$items);
    this.$header = $("<header></header>");
    this.$el.append(this.$header);
    if (this.parentList) {
      this.$backBtn = $("<a href='#/" + this.parentList.path + "' class='back silent'></a>");
      this.$backBtn.on('click', (function(_this) {
        return function(e) {
          return _this._back(e);
        };
      })(this));
    } else {
      this.$backBtn = $("<a href='#/' class='back'></a>");
    }
    this.$header.prepend(this.$backBtn);
    this.$header.append("<div class='spinner'></div>");
    this.$header.append("<span class='title'>" + this.title + "</span>");
    if (!this.config.disableNewItems && this.config.formSchema) {
      this.$newBtn = $("<a href='#/" + this.path + "/new' class='new silent'></a>");
      this.$newBtn.on('click', (function(_this) {
        return function(e) {
          return _this._new(e);
        };
      })(this));
      this.$header.append(this.$newBtn);
    }
    if (this.config.items) {
      this._process_config_items();
    }
    if (this.config.arrayStore) {
      this._bind_config_array_store();
    }
    if (this.config.objectStore) {
      this._bind_config_object_store();
    }
    this._bind_hashchange();
    if (typeof (base = this.config).onListInit === "function") {
      base.onListInit(this);
    }
  }

  List.prototype._bind_hashchange = function() {
    return $(chr).on('hashchange', (function(_this) {
      return function() {
        return _this._set_active_item();
      };
    })(this));
  };

  List.prototype._set_active_item = function() {
    var a, hash, i, itemPath, len, ref;
    hash = window.location.hash;
    if (hash.startsWith("#/" + this.module.name)) {
      ref = this.$items.children();
      for (i = 0, len = ref.length; i < len; i++) {
        a = ref[i];
        itemPath = $(a).attr('href');
        if (hash.startsWith(itemPath)) {
          return $(a).addClass('active');
        }
      }
    }
  };

  List.prototype._path = function() {
    var crumbs, l;
    crumbs = [];
    l = this;
    while (l.parentList) {
      crumbs.push(l.name);
      l = l.parentList;
    }
    return this.module.name + (crumbs.length > 0 ? '/' + crumbs.reverse().join('/') : '');
  };

  List.prototype._add_item = function(path, object, position, config) {
    var item;
    item = new this.itemClass(this.module, path, object, config);
    this.items[object._id] = item;
    return this._update_item_position(item, position);
  };

  List.prototype._update_item_position = function(item, position) {
    position = this.configItemsCount + position;
    if (position === 0) {
      return this.$items.prepend(item.$el);
    } else {
      this.$items.append(item.$el.hide());
      return $(this.$items.children()[position - 1]).after(item.$el.show());
    }
  };

  List.prototype._show_spinner = function() {
    return this.$el.addClass('show-spinner');
  };

  List.prototype._hide_spinner = function() {
    return this.$el.removeClass('show-spinner');
  };

  List.prototype._back = function(e) {
    this.module.chr.unsetActiveListItems();
    this.module.destroyView();
    if (this.showWithParent) {
      return this.hide();
    } else {
      return this.module.hideActiveList();
    }
  };

  List.prototype._new = function(e) {
    chr.updateHash($(e.currentTarget).attr('href'), true);
    return this.module.showView(null, this.config, 'New');
  };

  List.prototype.hide = function() {
    return this.$el.hide();
  };

  List.prototype.show = function(callback) {
    return this.$el.show(0, (function(_this) {
      return function() {
        var base;
        _this.$items.scrollTop(0);
        if (typeof (base = _this.config).onListShow === "function") {
          base.onListShow(_this);
        }
        return typeof callback === "function" ? callback() : void 0;
      };
    })(this));
  };

  List.prototype.updateItems = function() {
    if (!this.config.disableUpdateItems) {
      if (this.config.arrayStore) {
        this._show_spinner();
        return this.config.arrayStore.reset();
      }
    }
  };

  List.prototype.isVisible = function() {
    return this.$el.is(':visible');
  };

  return List;

})();

include(List, listConfig);

include(List, listPagination);

include(List, listReorder);

include(List, listSearch);

this.Item = (function() {
  function Item(module, path, object, config) {
    this.module = module;
    this.path = path;
    this.object = object;
    this.config = config;
    this.$el = $("<a class='item' href='" + this.path + "' data-id='" + this.object._id + "' data-title=''></a>");
    this.$el.on('click', (function(_this) {
      return function(e) {
        return _this._click(e);
      };
    })(this));
    this.render();
  }

  Item.prototype._is_folder = function() {
    if (this.object._title) {
      return true;
    } else {
      return false;
    }
  };

  Item.prototype._render_title = function() {
    var title;
    title = this.object._title;
    if (title == null) {
      title = this.object[this.config.itemTitleField];
    }
    if (title == null) {
      title = _firstNonEmptyValue(this.object);
    }
    if (title == null) {
      title = "No Title";
    }
    title = title.plainText();
    this.$title = $("<div class='item-title'>" + title + "</div>");
    this.$el.append(this.$title);
    return this.$el.attr('data-title', title);
  };

  Item.prototype._render_subtitle = function() {
    var subtitle;
    if (this.config.itemSubtitleField) {
      subtitle = this.object[this.config.itemSubtitleField];
      if (subtitle !== '') {
        this.$subtitle = $("<div class='item-subtitle'>" + subtitle + "</div>");
        this.$el.append(this.$subtitle);
        return this.$el.addClass('has-subtitle');
      }
    }
  };

  Item.prototype._render_thumbnail = function() {
    var imageUrl;
    if (this.config.itemThumbnail) {
      imageUrl = this.config.itemThumbnail(this.object);
      if (imageUrl !== '' && !imageUrl.endsWith('_old_')) {
        this.$thumbnail = $("<div class='item-thumbnail'><img src='" + imageUrl + "' /></div>");
        this.$el.append(this.$thumbnail);
        return this.$el.addClass('has-thumbnail');
      }
    }
  };

  Item.prototype._click = function(e) {
    var crumbs, hash, id, title;
    if (this.$el.hasClass('active')) {
      e.preventDefault();
      return;
    }
    hash = $(e.currentTarget).attr('href');
    crumbs = hash.split('/');
    title = $(e.currentTarget).attr('data-title');
    id = $(e.currentTarget).attr('data-id');
    chr.updateHash(hash, true);
    if (crumbs[crumbs.length - 2] === 'view') {
      return this.module.showViewByObjectId(id, this.config, title);
    }
    if (this.config.objectStore) {
      return this.module.showViewByObjectId('', this.config, title);
    }
    return this.module.showNestedList(_last(crumbs));
  };

  Item.prototype.render = function() {
    this.$el.html('').removeClass('item-folder has-subtitle has-thumbnail');
    this._render_title();
    if (this._is_folder()) {
      this.$el.addClass('item-folder');
      return this.$el.append($("<div class='icon-folder'></div>"));
    } else {
      this._render_subtitle();
      this._render_thumbnail();
      if (this.config.arrayStore && this.config.arrayStore.reorderable) {
        this.$el.addClass('reorderable');
        return this.$el.append($("<div class='icon-reorder'></div>"));
      }
    }
  };

  Item.prototype.destroy = function() {
    return this.$el.remove();
  };

  Item.prototype.position = function() {
    var positionFieldName;
    positionFieldName = this.config.arrayStore.sortBy;
    return parseFloat(this.object[positionFieldName]);
  };

  return Item;

})();

this.View = (function() {
  function View(module, config, closePath, object, title1) {
    var ref, ref1;
    this.module = module;
    this.config = config;
    this.closePath = closePath;
    this.object = object;
    this.title = title1;
    this.store = (ref = this.config.arrayStore) != null ? ref : this.config.objectStore;
    this.$el = $("<section class='view " + this.module.name + "' style='display:none;'>");
    if (this.config.fullsizeView) {
      this.$el.addClass('fullsize');
    }
    this.$header = $("<header></header>");
    this.$title = $("<div class='title'></div>");
    this.$header.append(this.$title);
    this.$el.append(this.$header);
    this._set_title();
    this.$closeBtn = $("<a href='#/" + this.closePath + "' class='close silent'>Close</a>");
    this.$closeBtn.on('click', (function(_this) {
      return function(e) {
        return _this._close(e);
      };
    })(this));
    this.$header.append(this.$closeBtn);
    if (!this.config.disableSave) {
      this.$saveBtn = $("<a href='#' class='save'>Save</a>");
      this.$saveBtn.on('click', (function(_this) {
        return function(e) {
          return _this._save(e);
        };
      })(this));
      this.$header.append(this.$saveBtn);
    }
    this.form = new ((ref1 = this.config.formClass) != null ? ref1 : Form)(this.object, this.config);
    this.$el.append(this.form.$el);
    this._add_form_delete_button();
  }

  View.prototype._set_title = function(reset) {
    var title;
    if (reset == null) {
      reset = false;
    }
    if (reset && this.config.arrayStore) {
      this.title = null;
    }
    title = this.title;
    if (this.config.itemTitleField) {
      if (title == null) {
        title = this.object[this.config.itemTitleField];
      }
    }
    if (title == null) {
      title = _firstNonEmptyValue(this.object);
    }
    return this.$title.html(title.plainText());
  };

  View.prototype._add_form_delete_button = function() {
    if (!(this.config.disableDelete || this.config.objectStore || (!this.object))) {
      this.$deleteBtn = $("<a href='#' class='delete'>Delete</a>");
      this.$deleteBtn.on('click', (function(_this) {
        return function(e) {
          return _this._delete(e);
        };
      })(this));
      return this.form.$el.append(this.$deleteBtn);
    }
  };

  View.prototype._save_success = function() {
    this.$el.removeClass('view-saving');
    this._set_title(true);
    return this.form.updateValues(this.object);
  };

  View.prototype._save_error = function(message, validationErrors) {
    this.$el.removeClass('view-saving');
    chr.showError(message);
    return this.form.showValidationErrors(validationErrors);
  };

  View.prototype._close = function(e) {
    return this.destroy();
  };

  View.prototype._save = function(e) {
    var serializedFormObj;
    e.preventDefault();
    this.$el.addClass('view-saving');
    serializedFormObj = this.form.serialize();
    if (this.object) {
      return this.store.update(this.object._id, serializedFormObj, {
        onSuccess: (function(_this) {
          return function(object) {
            _this.object = object;
            return _this._save_success();
          };
        })(this),
        onError: (function(_this) {
          return function(errors) {
            return _this._save_error('Changes were not saved.', errors);
          };
        })(this)
      });
    } else {
      return this.store.push(serializedFormObj, {
        onSuccess: (function(_this) {
          return function(object) {
            _this.object = object;
            _this._save_success();
            _this._add_form_delete_button();
            return chr.updateHash("#/" + _this.closePath + "/view/" + _this.object._id, true);
          };
        })(this),
        onError: (function(_this) {
          return function(errors) {
            return _this._save_error('Item were not created.', errors);
          };
        })(this)
      });
    }
  };

  View.prototype._delete = function(e) {
    e.preventDefault();
    if (confirm("Are you sure?")) {
      return this.store.remove(this.object._id, {
        onSuccess: (function(_this) {
          return function() {
            chr.updateHash("#/" + _this.closePath, true);
            return _this.destroy();
          };
        })(this),
        onError: function() {
          return chr.showError('Can\'t delete object.');
        }
      });
    }
  };

  View.prototype.show = function(callback) {
    return this.$el.show(0, (function(_this) {
      return function() {
        var base;
        if (typeof callback === "function") {
          callback();
        }
        _this.form.initializePlugins();
        return typeof (base = _this.config).onViewShow === "function" ? base.onViewShow(_this) : void 0;
      };
    })(this));
  };

  View.prototype.destroy = function() {
    this.form.destroy();
    return this.$el.remove();
  };

  return View;

})();

this.Form = (function() {
  function Form(object1, config1) {
    this.object = object1;
    this.config = config1;
    this.groups = [];
    this.inputs = {};
    this.$el = $(this.config.rootEl || '<form>');
    this.schema = this._get_schema();
    this.isRemoved = false;
    this._build_schema(this.schema, this.$el);
    this._add_nested_form_remove_button();
  }

  Form.prototype._get_schema = function() {
    var schema;
    schema = this.config.formSchema;
    if (this.object) {
      if (schema == null) {
        schema = this._generate_default_schema();
      }
    }
    return schema;
  };

  Form.prototype._generate_default_schema = function() {
    var key, ref, schema, value;
    schema = {};
    ref = this.object;
    for (key in ref) {
      value = ref[key];
      schema[key] = this._generate_default_input_config(key, value);
    }
    return schema;
  };

  Form.prototype._generate_default_input_config = function(fieldName, value) {
    var config;
    config = {};
    if (fieldName[0] === '_') {
      config.type = 'hidden';
    } else if (value === true || value === false) {
      config.type = 'checkbox';
    } else if (value) {
      if (value.hasOwnProperty('url')) {
        config.type = 'file';
      } else if (value.length > 60) {
        config.type = 'text';
      }
    }
    return config;
  };

  Form.prototype._build_schema = function(schema, $el) {
    var config, fieldName, group, input, results;
    results = [];
    for (fieldName in schema) {
      config = schema[fieldName];
      if (config.type === 'group') {
        group = this._generate_inputs_group(fieldName, config);
        results.push($el.append(group.$el));
      } else {
        input = this._generate_input(fieldName, config);
        results.push($el.append(input.$el));
      }
    }
    return results;
  };

  Form.prototype._generate_inputs_group = function(klassName, groupConfig) {
    var $group, group;
    $group = $("<div class='group " + klassName + "' />");
    if (groupConfig.inputs) {
      this._build_schema(groupConfig.inputs, $group);
    }
    group = {
      $el: $group,
      klassName: klassName,
      onInitialize: groupConfig.onInitialize
    };
    this.groups.push(group);
    return group;
  };

  Form.prototype._generate_input = function(fieldName, inputConfig) {
    var input, inputName, value;
    if (this.object) {
      value = this.object[fieldName];
    } else {
      value = inputConfig["default"];
    }
    if (value == null) {
      value = '';
    }
    inputName = inputConfig.name || fieldName;
    input = this._render_input(inputName, inputConfig, value);
    this.inputs[fieldName] = input;
    return input;
  };

  Form.prototype._render_input = function(name, config, value) {
    var inputClass, inputConfig, inputName;
    inputConfig = $.extend({}, config);
    if (inputConfig.label == null) {
      inputConfig.label = name.titleize();
    }
    if (inputConfig.type == null) {
      inputConfig.type = 'string';
    }
    if (inputConfig.klass == null) {
      inputConfig.klass = 'stacked';
    }
    inputConfig.klassName = name;
    inputClass = chr.formInputs[inputConfig.type];
    if (inputClass == null) {
      inputClass = chr.formInputs['string'];
    }
    inputName = this.config.namePrefix ? this.config.namePrefix + "[" + name + "]" : "[" + name + "]";
    if (inputConfig.type === 'form') {
      inputConfig.namePrefix = inputName.replace("[" + name + "]", "[" + name + "_attributes]");
    } else {
      inputConfig.namePrefix = this.config.namePrefix;
    }
    return new inputClass(inputName, value, inputConfig, this.object);
  };

  Form.prototype._add_nested_form_remove_button = function() {
    var fieldName, input;
    if (this.config.removeButton) {
      fieldName = '_destroy';
      input = this._render_input(fieldName, {
        type: 'hidden'
      }, false);
      this.inputs[fieldName] = input;
      this.$el.append(input.$el);
      this.$removeButton = $("<a href='#' class='nested-form-delete'>Delete</a>");
      this.$el.append(this.$removeButton);
      return this.$removeButton.on('click', (function(_this) {
        return function(e) {
          var base;
          e.preventDefault();
          if (confirm('Are you sure?')) {
            input.updateValue('true');
            _this.$el.hide();
            _this.isRemoved = true;
            return typeof (base = _this.config).onRemove === "function" ? base.onRemove(_this) : void 0;
          }
        };
      })(this));
    }
  };

  Form.prototype._forms = function() {
    var addNestedForms, forms;
    forms = [this];
    addNestedForms = function(form) {
      var input, name, ref, results;
      ref = form.inputs;
      results = [];
      for (name in ref) {
        input = ref[name];
        if (input.config.type === 'form') {
          forms = forms.concat(input.forms);
          results.push((function() {
            var i, len, ref1, results1;
            ref1 = input.forms;
            results1 = [];
            for (i = 0, len = ref1.length; i < len; i++) {
              form = ref1[i];
              results1.push(addNestedForms(form));
            }
            return results1;
          })());
        } else {
          results.push(void 0);
        }
      }
      return results;
    };
    addNestedForms(this);
    return forms;
  };

  Form.prototype.destroy = function() {
    var group, i, input, len, name, ref, ref1;
    ref = this.groups;
    for (i = 0, len = ref.length; i < len; i++) {
      group = ref[i];
      if (typeof group.destroy === "function") {
        group.destroy();
      }
    }
    ref1 = this.inputs;
    for (name in ref1) {
      input = ref1[name];
      if (typeof input.destroy === "function") {
        input.destroy();
      }
    }
    return this.$el.remove();
  };

  Form.prototype.serialize = function(obj) {
    var file, form, i, input, j, len, len1, name, ref, ref1, ref2, ref3;
    if (obj == null) {
      obj = {};
    }
    ref = this.$el.serializeArray();
    for (i = 0, len = ref.length; i < len; i++) {
      input = ref[i];
      obj[input.name] = input.value;
    }
    ref1 = this._forms();
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      form = ref1[j];
      ref2 = form.inputs;
      for (name in ref2) {
        input = ref2[name];
        if (input.config.type === 'file' || input.config.type === 'image') {
          file = input.$input.get()[0].files[0];
          obj["__FILE__" + input.name] = file;
          if (input.isEmpty()) {
            obj[input.removeName()] = 'true';
          }
        }
      }
      ref3 = form.inputs;
      for (name in ref3) {
        input = ref3[name];
        if (input.config.ignoreOnSubmission) {
          delete obj[name];
        }
      }
    }
    return obj;
  };

  Form.prototype.hash = function(hash) {
    var input, name, ref;
    if (hash == null) {
      hash = {};
    }
    ref = this.inputs;
    for (name in ref) {
      input = ref[name];
      input.hash(hash);
    }
    return hash;
  };

  Form.prototype.initializePlugins = function() {
    var group, i, input, len, name, ref, ref1, results;
    ref = this.groups;
    for (i = 0, len = ref.length; i < len; i++) {
      group = ref[i];
      if (typeof group.onInitialize === "function") {
        group.onInitialize(this, group);
      }
    }
    ref1 = this.inputs;
    results = [];
    for (name in ref1) {
      input = ref1[name];
      results.push(input.initialize());
    }
    return results;
  };

  Form.prototype.showValidationErrors = function(errors) {
    var firstMessage, input, inputName, messages, results;
    this.hideValidationErrors();
    results = [];
    for (inputName in errors) {
      messages = errors[inputName];
      input = this.inputs[inputName];
      firstMessage = messages[0];
      results.push(input.showErrorMessage(firstMessage));
    }
    return results;
  };

  Form.prototype.hideValidationErrors = function() {
    var input, inputName, ref, results;
    ref = this.inputs;
    results = [];
    for (inputName in ref) {
      input = ref[inputName];
      results.push(input.hideErrorMessage());
    }
    return results;
  };

  Form.prototype.updateValues = function(object) {
    var name, results, value;
    results = [];
    for (name in object) {
      value = object[name];
      if (this.inputs[name]) {
        results.push(this.inputs[name].updateValue(value, object));
      } else {
        results.push(void 0);
      }
    }
    return results;
  };

  return Form;

})();

this.inputFormReorder = {
  _bind_forms_reorder: function() {
    var form, i, len, list, ref, results;
    if (this.config.sortBy) {
      list = this.$forms.addClass(this.reorderContainerClass).get(0);
      new Slip(list);
      list.addEventListener('slip:beforeswipe', function(e) {
        return e.preventDefault();
      });
      list.addEventListener('slip:beforewait', (function(e) {
        if ($(e.target).hasClass("icon-reorder")) {
          return e.preventDefault();
        }
      }), false);
      list.addEventListener('slip:beforereorder', (function(e) {
        if (!$(e.target).hasClass("icon-reorder")) {
          return e.preventDefault();
        }
      }), false);
      list.addEventListener('slip:reorder', ((function(_this) {
        return function(e) {
          var $targetForm, newTargetFormPosition, nextForm, nextFormPosition, prevForm, prevFormPosition, targetForm;
          targetForm = _this._find_form_by_target(e.target);
          if (targetForm) {
            e.target.parentNode.insertBefore(e.target, e.detail.insertBefore);
            $targetForm = $(e.target);
            prevForm = _this._find_form_by_target($targetForm.prev().get(0));
            nextForm = _this._find_form_by_target($targetForm.next().get(0));
            prevFormPosition = prevForm ? prevForm.inputs[_this.config.sortBy].value : 0;
            nextFormPosition = nextForm ? nextForm.inputs[_this.config.sortBy].value : 0;
            newTargetFormPosition = prevFormPosition + Math.abs(nextFormPosition - prevFormPosition) / 2.0;
            targetForm.inputs[_this.config.sortBy].updateValue(newTargetFormPosition);
          }
          return false;
        };
      })(this)), false);
      ref = this.forms;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        form = ref[i];
        results.push(this._add_form_reorder_button(form));
      }
      return results;
    }
  },
  _add_form_reorder_button: function(form) {
    return form.$el.append("<div class='icon-reorder' data-container-class='" + this.reorderContainerClass + "'></div>").addClass('reorderable');
  },
  _find_form_by_target: function(el) {
    var form, i, len, ref;
    if (el) {
      ref = this.forms;
      for (i = 0, len = ref.length; i < len; i++) {
        form = ref[i];
        if (form.$el.get(0) === el) {
          return form;
        }
      }
    }
    return null;
  }
};

this.InputForm = (function() {
  function InputForm(name1, nestedObjects, config1, object1) {
    var base;
    this.name = name1;
    this.nestedObjects = nestedObjects;
    this.config = config1;
    this.object = object1;
    this.forms = [];
    (base = this.config).namePrefix || (base.namePrefix = name);
    this.config.removeButton = true;
    this.config.formSchema._id = {
      type: 'hidden',
      name: 'id'
    };
    this.reorderContainerClass = "nested-forms-" + this.config.klassName;
    this._create_el();
    this._add_label();
    this._add_forms();
    this._add_new_button();
    return this;
  }

  InputForm.prototype._create_el = function() {
    return this.$el = $("<div class='input-stacked nested-forms " + this.config.klassName + "'>");
  };

  InputForm.prototype._add_label = function() {
    this.$label = $("<span class='label'>" + this.config.label + "</span>");
    this.$errorMessage = $("<span class='error-message'></span>");
    this.$label.append(this.$errorMessage);
    return this.$el.append(this.$label);
  };

  InputForm.prototype._add_forms = function() {
    var i, namePrefix, object, ref;
    this.$forms = $("<ul>");
    this.$label.after(this.$forms);
    if (this.nestedObjects !== '') {
      this._sort_nested_objects();
      ref = this.nestedObjects;
      for (i in ref) {
        object = ref[i];
        namePrefix = this.config.namePrefix + "[" + i + "]";
        this.forms.push(this._render_form(object, namePrefix, this.config));
      }
      return this._bind_forms_reorder();
    }
  };

  InputForm.prototype._sort_nested_objects = function() {
    var i, o, ref, results;
    if (this.config.sortBy) {
      this.config.formSchema[this.config.sortBy] = {
        type: 'hidden'
      };
      if (this.nestedObjects) {
        this.nestedObjects.sort((function(_this) {
          return function(a, b) {
            return parseFloat(a[_this.config.sortBy]) - parseFloat(b[_this.config.sortBy]);
          };
        })(this));
        ref = this.nestedObjects;
        results = [];
        for (i in ref) {
          o = ref[i];
          results.push(o[this.config.sortBy] = parseInt(i) + 1);
        }
        return results;
      }
    }
  };

  InputForm.prototype._render_form = function(object, namePrefix, config) {
    var form, formConfig;
    formConfig = $.extend({}, config, {
      namePrefix: namePrefix,
      rootEl: "<li>"
    });
    form = new Form(object, formConfig);
    this.$forms.append(form.$el);
    return form;
  };

  InputForm.prototype._add_new_button = function() {
    var label;
    label = this.config.newButtonLabel || "Add";
    this.$newButton = $("<a href='#' class='nested-form-new'>" + label + "</a>");
    this.$el.append(this.$newButton);
    return this.$newButton.on('click', (function(_this) {
      return function(e) {
        e.preventDefault();
        return _this.addNewForm();
      };
    })(this));
  };

  InputForm.prototype.initialize = function() {
    var base, j, len, nestedForm, ref;
    ref = this.forms;
    for (j = 0, len = ref.length; j < len; j++) {
      nestedForm = ref[j];
      nestedForm.initializePlugins();
    }
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  InputForm.prototype.hash = function(hash) {
    var form, j, len, ref;
    if (hash == null) {
      hash = {};
    }
    hash[this.config.klassName] = [];
    ref = this.forms;
    for (j = 0, len = ref.length; j < len; j++) {
      form = ref[j];
      hash[this.config.klassName].push(form.hash());
    }
    return hash;
  };

  InputForm.prototype.showErrorMessage = function(message) {
    this.$el.addClass('error');
    return this.$errorMessage.html(message);
  };

  InputForm.prototype.hideErrorMessage = function() {
    this.$el.removeClass('error');
    return this.$errorMessage.html('');
  };

  InputForm.prototype.addNewForm = function(object) {
    var base, form, namePrefix, newFormConfig, position, prevForm;
    if (object == null) {
      object = null;
    }
    namePrefix = this.config.namePrefix + "[" + (Date.now()) + "]";
    newFormConfig = $.extend({}, this.config);
    delete newFormConfig.formSchema._id;
    form = this._render_form(object, namePrefix, newFormConfig);
    form.initializePlugins();
    if (this.config.sortBy) {
      this._add_form_reorder_button(form);
      prevForm = _last(this.forms);
      position = prevForm ? prevForm.inputs[this.config.sortBy].value + 1 : 1;
      form.inputs[this.config.sortBy].updateValue(position);
    }
    this.forms.push(form);
    if (typeof (base = this.config).onNew === "function") {
      base.onNew(form);
    }
    return form;
  };

  InputForm.prototype.updateValue = function(nestedObjects, object1) {
    this.nestedObjects = nestedObjects;
    this.object = object1;
    this.$forms.remove();
    this.forms = [];
    return this._add_forms();
  };

  return InputForm;

})();

include(InputForm, inputFormReorder);

chr.formInputs['form'] = InputForm;

this.InputString = (function() {
  function InputString(name, value, config, object) {
    this.name = name;
    this.value = value;
    this.config = config;
    this.object = object;
    this._create_el();
    this._add_label();
    this._add_input();
    this._add_placeholder();
    return this;
  }

  InputString.prototype._safe_value = function() {
    if (typeof this.value === 'object') {
      return JSON.stringify(this.value);
    } else {
      return _escapeHtml(this.value);
    }
  };

  InputString.prototype._create_el = function() {
    return this.$el = $("<label for='" + this.name + "' class='input-" + this.config.type + " input-" + this.config.klass + " " + this.config.klassName + "'>");
  };

  InputString.prototype._add_label = function() {
    this.$label = $("<span class='label'>" + this.config.label + "</span>");
    this.$errorMessage = $("<span class='error-message'></span>");
    this.$label.append(this.$errorMessage);
    return this.$el.append(this.$label);
  };

  InputString.prototype._add_input = function() {
    var data;
    this.$input = $("<input type='text' name='" + this.name + "' value='" + (this._safe_value()) + "' />");
    this.$el.append(this.$input);
    if (this.config.options && $.isArray(this.config.options)) {
      data = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        local: $.map(this.config.options, function(opt) {
          return {
            value: opt
          };
        })
      });
      data.initialize();
      return this.$input.typeahead({
        hint: true,
        highlight: true,
        minLength: 1
      }, {
        name: 'options',
        displayKey: 'value',
        source: data.ttAdapter()
      });
    }
  };

  InputString.prototype._add_placeholder = function() {
    var ref;
    if ((ref = this.config.klass) === 'placeholder' || ref === 'stacked') {
      this.$input.attr('placeholder', this.config.label);
    }
    if (this.config.placeholder) {
      return this.$input.attr('placeholder', this.config.placeholder);
    }
  };

  InputString.prototype.initialize = function() {
    var base;
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  InputString.prototype.hash = function(hash) {
    if (hash == null) {
      hash = {};
    }
    hash[this.config.klassName] = this.$input.val();
    return hash;
  };

  InputString.prototype.updateValue = function(value) {
    this.value = value;
    return this.$input.val(this.value);
  };

  InputString.prototype.showErrorMessage = function(message) {
    this.$el.addClass('error');
    return this.$errorMessage.html(message);
  };

  InputString.prototype.hideErrorMessage = function() {
    this.$el.removeClass('error');
    return this.$errorMessage.html('');
  };

  return InputString;

})();

chr.formInputs['string'] = InputString;

this.InputHidden = (function() {
  function InputHidden(name, value, config, object) {
    this.name = name;
    this.value = value;
    this.config = config;
    this.object = object;
    this._create_el();
    return this;
  }

  InputHidden.prototype._create_el = function() {
    return this.$el = $("<input type='hidden' name='" + this.name + "' value='" + (this._safe_value()) + "' />");
  };

  InputHidden.prototype._safe_value = function() {
    if (typeof this.value === 'object') {
      return JSON.stringify(this.value);
    } else {
      return _escapeHtml(this.value);
    }
  };

  InputHidden.prototype.initialize = function() {
    var base;
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  InputHidden.prototype.updateValue = function(value) {
    this.value = value;
    return this.$el.val(this._safe_value());
  };

  InputHidden.prototype.hash = function(hash) {
    if (hash == null) {
      hash = {};
    }
    hash[this.config.klassName] = this.$el.val();
    return hash;
  };

  InputHidden.prototype.showErrorMessage = function(message) {};

  InputHidden.prototype.hideErrorMessage = function() {};

  return InputHidden;

})();

chr.formInputs['hidden'] = InputHidden;

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputCheckbox = (function(superClass) {
  extend(InputCheckbox, superClass);

  function InputCheckbox(name, value, config, object) {
    this.name = name;
    this.value = value;
    this.config = config;
    this.object = object;
    this._create_el();
    this._add_input();
    this._add_label();
    return this;
  }

  InputCheckbox.prototype._create_el = function() {
    return this.$el = $("<label for='" + this.name + "' class='input-" + this.config.type + " input-" + this.config.klass + " " + this.config.klassName + "'>");
  };

  InputCheckbox.prototype._safe_value = function() {
    if (!this.value || this.value === 'false' || this.value === 0 || this.value === '0') {
      return false;
    } else {
      return true;
    }
  };

  InputCheckbox.prototype._add_input = function() {
    this.$false_hidden_input = $("<input type='hidden' name='" + this.name + "' value='false' />");
    this.$el.append(this.$false_hidden_input);
    this.$input = $("<input type='checkbox' id='" + this.name + "' name='" + this.name + "' value='true' " + (this._safe_value() ? 'checked' : '') + " />");
    return this.$el.append(this.$input);
  };

  InputCheckbox.prototype.updateValue = function(value) {
    this.value = value;
    return this.$input.prop('checked', this._safe_value());
  };

  InputCheckbox.prototype.hash = function(hash) {
    if (hash == null) {
      hash = {};
    }
    hash[this.config.klassName] = this.$input.prop('checked');
    return hash;
  };

  return InputCheckbox;

})(InputString);

chr.formInputs['checkbox'] = InputCheckbox;

this.InputCheckboxSwitch = (function(superClass) {
  extend(InputCheckboxSwitch, superClass);

  function InputCheckboxSwitch() {
    return InputCheckboxSwitch.__super__.constructor.apply(this, arguments);
  }

  InputCheckboxSwitch.prototype._add_input = function() {
    this.$switch = $("<div class='switch'>");
    this.$el.append(this.$switch);
    this.$false_hidden_input = $("<input type='hidden' name='" + this.name + "' value='false' />");
    this.$switch.append(this.$false_hidden_input);
    this.$input = $("<input type='checkbox' id='" + this.name + "' name='" + this.name + "' value='true' " + (this._safe_value() ? 'checked' : '') + " />");
    this.$switch.append(this.$input);
    this.$checkbox = $("<div class='checkbox'>");
    return this.$switch.append(this.$checkbox);
  };

  return InputCheckboxSwitch;

})(InputCheckbox);

chr.formInputs['switch'] = InputCheckboxSwitch;

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputColor = (function(superClass) {
  extend(InputColor, superClass);

  function InputColor() {
    return InputColor.__super__.constructor.apply(this, arguments);
  }

  InputColor.prototype._add_color_preview = function() {
    this.$colorPreview = $("<div class='preview'>");
    return this.$el.append(this.$colorPreview);
  };

  InputColor.prototype._update_color_preview = function() {
    return this.$colorPreview.css({
      'background-color': "#" + (this.$input.val())
    });
  };

  InputColor.prototype._validate_input_value = function() {
    if (/^(?:[0-9a-f]{3}){1,2}$/i.test(this.$input.val())) {
      return this.hideErrorMessage();
    } else {
      return this.showErrorMessage('Invalid hex value');
    }
  };

  InputColor.prototype.initialize = function() {
    var base;
    this.$input.attr('placeholder', this.config.placeholder || 'e.g. #eee');
    this._add_color_preview();
    this._update_color_preview();
    this.$input.on('change keyup', (function(_this) {
      return function(e) {
        _this.hideErrorMessage();
        _this._validate_input_value();
        return _this._update_color_preview();
      };
    })(this));
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  return InputColor;

})(InputString);

chr.formInputs['color'] = InputColor;



var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputFile = (function(superClass) {
  extend(InputFile, superClass);

  function InputFile(name, value, config, object) {
    this.name = name;
    this.value = value;
    this.config = config;
    this.object = object;
    this._create_el();
    this._add_label();
    this._add_input();
    this._update_state();
    return this;
  }

  InputFile.prototype._create_el = function() {
    return this.$el = $("<div class='input-" + this.config.type + " input-" + this.config.klass + " " + this.config.klassName + "'>");
  };

  InputFile.prototype._add_input = function() {
    this.$link = $("<a href='#' target='_blank' title=''></a>");
    this.$el.append(this.$link);
    this.$input = $("<input type='file' name='" + this.name + "' id='" + this.name + "'>");
    this.$el.append(this.$input);
    return this._add_remove_checkbox();
  };

  InputFile.prototype._add_remove_checkbox = function() {
    var removeInputName;
    removeInputName = this.removeName();
    this.$removeLabel = $("<label for='" + removeInputName + "'>Remove</label>");
    this.$hiddenRemoveInput = $("<input type='hidden' name='" + removeInputName + "' value='false'>");
    this.$removeInput = $("<input type='checkbox' name='" + removeInputName + "' id='" + removeInputName + "' value='true'>");
    this.$link.after(this.$removeLabel);
    this.$link.after(this.$removeInput);
    return this.$link.after(this.$hiddenRemoveInput);
  };

  InputFile.prototype._update_inputs = function() {
    return this.$link.html(this.filename).attr('title', this.filename).attr('href', this.value.url);
  };

  InputFile.prototype._update_state = function(filename) {
    this.filename = filename != null ? filename : null;
    this.$input.val('');
    this.$removeInput.prop('checked', false);
    if (this.value.url) {
      this.filename = _last(this.value.url.split('/'));
      if (this.filename === '_old_') {
        this.filename = null;
      }
    }
    if (this.filename) {
      this.$el.removeClass('empty');
      return this._update_inputs();
    } else {
      return this.$el.addClass('empty');
    }
  };

  InputFile.prototype.isEmpty = function() {
    return !this.$input.get()[0].files[0] && !this.filename;
  };

  InputFile.prototype.removeName = function() {
    return this.name.reverse().replace('[', '[remove_'.reverse()).reverse();
  };

  InputFile.prototype.updateValue = function(value, object) {
    this.value = value;
    this.object = object;
    return this._update_state();
  };

  return InputFile;

})(InputString);

chr.formInputs['file'] = InputFile;

this.InputFileImage = (function(superClass) {
  extend(InputFileImage, superClass);

  function InputFileImage() {
    return InputFileImage.__super__.constructor.apply(this, arguments);
  }

  InputFileImage.prototype._add_input = function() {
    this.$link = $("<a href='#' target='_blank' title=''></a>");
    this.$el.append(this.$link);
    this.$thumb = $("<img src='' />");
    this.$el.append(this.$thumb);
    this.$input = $("<input type='file' name='" + this.name + "' id='" + this.name + "' />");
    this.$el.append(this.$input);
    return this._add_remove_checkbox();
  };

  InputFileImage.prototype._update_inputs = function() {
    var image_thumb_url;
    this.$link.html(this.filename).attr('title', this.filename).attr('href', this.value.url);
    image_thumb_url = this.config.thumbnail ? this.config.thumbnail(this.object) : this.value.url;
    return this.$thumb.attr('src', image_thumb_url).attr('alt', this.filename);
  };

  return InputFileImage;

})(InputFile);

chr.formInputs['image'] = InputFileImage;

this.inputListReorder = {
  _bind_reorder: function() {
    var list;
    list = this.$items.get(0);
    new Slip(list);
    list.addEventListener('slip:beforeswipe', function(e) {
      return e.preventDefault();
    });
    list.addEventListener('slip:beforewait', (function(e) {
      if ($(e.target).hasClass("icon-reorder")) {
        return e.preventDefault();
      }
    }), false);
    list.addEventListener('slip:beforereorder', (function(e) {
      if (!$(e.target).hasClass("icon-reorder")) {
        return e.preventDefault();
      }
    }), false);
    return list.addEventListener('slip:reorder', ((function(_this) {
      return function(e) {
        e.target.parentNode.insertBefore(e.target, e.detail.insertBefore);
        _this._update_input_value();
        return false;
      };
    })(this)), false);
  }
};

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputList = (function(superClass) {
  extend(InputList, superClass);

  function InputList() {
    return InputList.__super__.constructor.apply(this, arguments);
  }

  InputList.prototype._add_input = function() {
    var name, placeholder;
    name = this.config.namePrefix ? this.config.namePrefix + "[__LIST__" + this.config.target + "]" : "[__LIST__" + this.config.target + "]";
    this.$input = $("<input type='hidden' name='" + name + "' value='' />");
    this.$el.append(this.$input);
    if (this.config.typeahead) {
      placeholder = this.config.typeahead.placeholder;
      this.typeaheadInput = $("<input type='text' placeholder='" + placeholder + "' />");
      this.$el.append(this.typeaheadInput);
    }
    this._add_items();
    return this._update_input_value();
  };

  InputList.prototype._update_input_value = function() {
    var ids, value;
    ids = [];
    this.$items.children('li').each(function(i, el) {
      return ids.push($(el).attr('data-id'));
    });
    value = ids.join(',');
    return this.$input.val(value);
  };

  InputList.prototype._remove_item = function($el) {
    var id;
    id = $el.attr('data-id');
    delete this.objects[id];
    $el.parent().remove();
    return this._update_input_value();
  };

  InputList.prototype._add_item = function(o) {
    var id, item, listItem;
    id = o['_id'];
    this.objects[id] = o;
    if (this.config.itemTemplate) {
      item = this.config.itemTemplate(o);
    } else {
      item = o[this.config.titleFieldName];
    }
    listItem = $("<li data-id='" + id + "'>\n  <span class='icon-reorder' data-container-class='" + this.reorderContainerClass + "'></span>\n  " + item + "\n  <a href='#' class='action_remove'>Remove</a>\n</li>");
    this.$items.append(listItem);
    return this._update_input_value();
  };

  InputList.prototype._add_items = function() {
    var j, len, o, ref;
    this.reorderContainerClass = this.config.klassName;
    this.objects = {};
    this.$items = $("<ul class='" + this.reorderContainerClass + "'></ul>");
    ref = this.value;
    for (j = 0, len = ref.length; j < len; j++) {
      o = ref[j];
      this._add_item(o);
    }
    return this.typeaheadInput.before(this.$items);
  };

  InputList.prototype.initialize = function() {
    var base, dataSource, limit;
    if (this.config.typeahead) {
      limit = this.config.typeahead.limit || 5;
      dataSource = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace(this.config.titleFieldName),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: this.config.typeahead.url,
        limit: limit
      });
      dataSource.initialize();
      this.typeaheadInput.typeahead({
        hint: false,
        highlight: true
      }, {
        name: this.config.klassName,
        displayKey: this.config.titleFieldName,
        source: dataSource.ttAdapter()
      });
      this.typeaheadInput.on('typeahead:selected', (function(_this) {
        return function(e, object, dataset) {
          _this._add_item(object);
          return _this.typeaheadInput.typeahead('val', '');
        };
      })(this));
    }
    this.$items.on('click', '.action_remove', (function(_this) {
      return function(e) {
        e.preventDefault();
        if (confirm('Are you sure?')) {
          return _this._remove_item($(e.currentTarget));
        }
      };
    })(this));
    this._bind_reorder();
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  InputList.prototype.hash = function(hash) {
    var id, ids, j, len;
    if (hash == null) {
      hash = {};
    }
    hash[this.config.klassName] = [];
    ids = this.$input.val().split(',');
    for (j = 0, len = ids.length; j < len; j++) {
      id = ids[j];
      hash[this.config.klassName].push(this.objects[id]);
    }
    return hash;
  };

  InputList.prototype.updateValue = function(value1) {
    var j, len, o, ref, results;
    this.value = value1;
    this.$items.html('');
    ref = this.value;
    results = [];
    for (j = 0, len = ref.length; j < len; j++) {
      o = ref[j];
      results.push(this._add_item(o));
    }
    return results;
  };

  return InputList;

})(InputString);

include(InputList, inputListReorder);

chr.formInputs['list'] = InputList;

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputPassword = (function(superClass) {
  extend(InputPassword, superClass);

  function InputPassword() {
    return InputPassword.__super__.constructor.apply(this, arguments);
  }

  InputPassword.prototype._add_input = function() {
    this.$input = $("<input type='password' name='" + this.name + "' value='" + this.value + "' />");
    return this.$el.append(this.$input);
  };

  InputPassword.prototype.updateValue = function(value) {
    this.value = value;
    return this.$input.val(this.value);
  };

  return InputPassword;

})(InputString);

chr.formInputs['password'] = InputPassword;

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputSelect = (function(superClass) {
  extend(InputSelect, superClass);

  function InputSelect() {
    return InputSelect.__super__.constructor.apply(this, arguments);
  }

  InputSelect.prototype._create_el = function() {
    return this.$el = $("<div class='input-" + this.config.type + " input-" + this.config.klass + " " + this.config.klassName + "'>");
  };

  InputSelect.prototype._add_input = function() {
    this.$input = $("<select name='" + this.name + "' id='" + this.name + "'></select>");
    this.$el.append(this.$input);
    if (this.config.optionsHashFieldName) {
      this.value = String(this.value);
      if (this.object) {
        this.config.optionsHash = this.object[this.config.optionsHashFieldName];
      } else {
        this.config.optionsHash = {
          '': '--'
        };
      }
    }
    return this._add_options();
  };

  InputSelect.prototype._add_options = function() {
    if (this.config.collection) {
      return this._add_collection_options();
    } else if (this.config.optionsList) {
      return this._add_list_options();
    } else if (this.config.optionsHash) {
      return this._add_hash_options();
    }
  };

  InputSelect.prototype._add_collection_options = function() {
    var i, len, o, ref, results, title, value;
    ref = this.config.collection.data;
    results = [];
    for (i = 0, len = ref.length; i < len; i++) {
      o = ref[i];
      title = o[this.config.collection.titleField];
      value = o[this.config.collection.valueField];
      results.push(this._add_option(title, value));
    }
    return results;
  };

  InputSelect.prototype._add_list_options = function() {
    var data, i, len, o, results;
    data = this.config.optionsList;
    results = [];
    for (i = 0, len = data.length; i < len; i++) {
      o = data[i];
      results.push(this._add_option(o, o));
    }
    return results;
  };

  InputSelect.prototype._add_hash_options = function() {
    var data, results, title, value;
    data = this.config.optionsHash;
    results = [];
    for (value in data) {
      title = data[value];
      results.push(this._add_option(title, value));
    }
    return results;
  };

  InputSelect.prototype._add_option = function(title, value) {
    var $option, selected;
    selected = this.value === value ? 'selected' : '';
    $option = $("<option value='" + value + "' " + selected + ">" + title + "</option>");
    return this.$input.append($option);
  };

  InputSelect.prototype.updateValue = function(value1) {
    this.value = value1;
    return this.$input.val(this.value).prop('selected', true);
  };

  return InputSelect;

})(InputString);

chr.formInputs['select'] = InputSelect;

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.InputText = (function(superClass) {
  extend(InputText, superClass);

  function InputText() {
    return InputText.__super__.constructor.apply(this, arguments);
  }

  InputText.prototype._add_input = function() {
    this.$input = $("<textarea class='autosize' name='" + this.name + "' rows=1>" + (this._safe_value()) + "</textarea>");
    return this.$el.append(this.$input);
  };

  InputText.prototype.initialize = function() {
    var base;
    this.$input.textareaAutoSize();
    return typeof (base = this.config).onInitialize === "function" ? base.onInitialize(this) : void 0;
  };

  return InputText;

})(InputString);

chr.formInputs['text'] = InputText;

this.ArrayStore = (function() {
  function ArrayStore(config) {
    var ref, ref1, ref2;
    this.config = config != null ? config : {};
    this._map = {};
    this._data = [];
    this.sortBy = (ref = this.config.sortBy) != null ? ref : false;
    this.sortReverse = (ref1 = this.config.sortReverse) != null ? ref1 : false;
    this.reorderable = (ref2 = this.config.reorderable) != null ? ref2 : false;
    this._initialize_reorderable();
    this._initialize_store();
  }

  ArrayStore.prototype._initialize_reorderable = function() {
    var ref;
    if (this.reorderable) {
      if (this.reorderable.positionFieldName) {
        this.sortBy = this.reorderable.positionFieldName;
        return this.sortReverse = (ref = this.reorderable.sortReverse) != null ? ref : false;
      } else {
        console.log('Wrong reordering configuration, missing positionFieldName parameter.');
        return this.reorderable = false;
      }
    }
  };

  ArrayStore.prototype._initialize_store = function() {};

  ArrayStore.prototype._sort_data = function() {
    var direction, fieldName, sortByMethod;
    if (this.sortBy) {
      fieldName = this.sortBy;
      direction = this.sortReverse ? 1 : -1;
      sortByMethod = function(key, a, b, dir) {
        if (a[key] > b[key]) {
          return -1 * dir;
        }
        if (a[key] < b[key]) {
          return +1 * dir;
        }
        return 0;
      };
      return this._data = this._data.sort(function(a, b) {
        return sortByMethod(fieldName, a, b, direction);
      });
    }
  };

  ArrayStore.prototype._get_data_object_position = function(id) {
    var i, ids, len, o, ref;
    ids = [];
    ref = this._data;
    for (i = 0, len = ref.length; i < len; i++) {
      o = ref[i];
      if (o) {
        ids.push(o._id);
      }
    }
    return $.inArray(id, ids);
  };

  ArrayStore.prototype._normalize_object_id = function(object) {
    if (object.id) {
      object._id = object.id;
      delete object.id;
    }
    return object;
  };

  ArrayStore.prototype._add_data_object = function(object) {
    var data, position;
    object = this._normalize_object_id(object);
    if (!this._map[object._id]) {
      this._map[object._id] = object;
      this._data.push(object);
      this._sort_data();
      position = this._get_data_object_position(object._id);
      data = {
        object: object,
        position: position
      };
      $(this).trigger('object_added', data);
      return data;
    } else {
      return this._update_data_object(object.id, object);
    }
  };

  ArrayStore.prototype._update_data_object = function(id, value) {
    var data, object, old_position, position;
    object = $.extend(this.get(id), value);
    old_position = this._get_data_object_position(id);
    this._sort_data();
    position = this._get_data_object_position(id);
    data = {
      object: object,
      position: position,
      positionHasChanged: old_position !== position
    };
    $(this).trigger('object_changed', data);
    return data;
  };

  ArrayStore.prototype._remove_data_object = function(id) {
    var data, position;
    position = this._get_data_object_position(id);
    if (position >= 0) {
      this._data.splice(position, 1);
    }
    delete this._map[id];
    data = {
      object_id: id
    };
    $(this).trigger('object_removed', data);
    return data;
  };

  ArrayStore.prototype._reset_data = function() {
    var id, o, ref;
    ref = this._map;
    for (id in ref) {
      o = ref[id];
      $(this).trigger('object_removed', {
        object_id: id
      });
    }
    this._map = {};
    return this._data = [];
  };

  ArrayStore.prototype._parse_form_object = function(serializedFormObject) {
    var fieldName, key, object, value;
    object = {};
    for (key in serializedFormObject) {
      value = serializedFormObject[key];
      fieldName = key.replace('[', '').replace(']', '');
      object[fieldName] = value;
    }
    return object;
  };

  ArrayStore.prototype.on = function(eventType, callback) {
    return $(this).on(eventType, function(e, data) {
      return callback(e, data);
    });
  };

  ArrayStore.prototype.off = function(eventType) {
    if (eventType) {
      return $(this).off(eventType);
    } else {
      return $(this).off();
    }
  };

  ArrayStore.prototype.get = function(id) {
    return this._map[id];
  };

  ArrayStore.prototype.push = function(serializedFormObject, callbacks) {
    var object;
    if (callbacks == null) {
      callbacks = {};
    }
    object = this._parse_form_object(serializedFormObject);
    if (!object._id) {
      object._id = Date.now();
    }
    this._add_data_object(object);
    return typeof callbacks.onSuccess === "function" ? callbacks.onSuccess() : void 0;
  };

  ArrayStore.prototype.update = function(id, serializedFormObject, callbacks) {
    var object;
    if (callbacks == null) {
      callbacks = {};
    }
    object = this._parse_form_object(serializedFormObject);
    this._update_data_object(id, object);
    return typeof callbacks.onSuccess === "function" ? callbacks.onSuccess() : void 0;
  };

  ArrayStore.prototype.remove = function(id, callbacks) {
    if (callbacks == null) {
      callbacks = {};
    }
    this._remove_data_object(id);
    return typeof callbacks.onSuccess === "function" ? callbacks.onSuccess() : void 0;
  };

  ArrayStore.prototype.reset = function() {
    return $(this).trigger('objects_added');
  };

  ArrayStore.prototype.addObjects = function(objects) {
    var i, len, o;
    for (i = 0, len = objects.length; i < len; i++) {
      o = objects[i];
      this._add_data_object(o);
    }
    return $(this).trigger('objects_added');
  };

  ArrayStore.prototype.data = function() {
    return this._data;
  };

  return ArrayStore;

})();

this.ObjectStore = (function() {
  function ObjectStore(config) {
    this.config = config != null ? config : {};
    this._initialize_store();
  }

  ObjectStore.prototype._initialize_store = function() {
    return this._data = this.config.data;
  };

  ObjectStore.prototype.loadObject = function() {
    return this._data;
  };

  ObjectStore.prototype.update = function(id, value, callback) {
    $.extend(this._data, value);
    return typeof callback === "function" ? callback(this._data) : void 0;
  };

  return ObjectStore;

})();

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.RestArrayStore = (function(superClass) {
  extend(RestArrayStore, superClass);

  function RestArrayStore() {
    return RestArrayStore.__super__.constructor.apply(this, arguments);
  }

  RestArrayStore.prototype._initialize_store = function() {
    var ref, ref1, ref2;
    this.dataFetchLock = false;
    this.lastPageLoaded = false;
    this.searchable = (ref = this.config.searchable) != null ? ref : false;
    this.searchQuery = '';
    this.pagination = (ref1 = this.config.pagination) != null ? ref1 : true;
    this.nextPage = 1;
    this.objectsPerPage = (ref2 = chr.itemsPerPageRequest) != null ? ref2 : 20;
    if (this.requestParams == null) {
      this.requestParams = {
        page: 'page',
        perPage: 'perPage',
        search: 'search'
      };
    }
    return this._configure_store();
  };

  RestArrayStore.prototype._configure_store = function() {
    return this.ajaxConfig = {};
  };

  RestArrayStore.prototype._resource_url = function(type, id) {
    var objectPath;
    objectPath = id ? "/" + id : '';
    return "" + this.config.path + objectPath;
  };

  RestArrayStore.prototype._request_url = function(type, id) {
    var extraParamsString, url;
    url = this._resource_url(type, id);
    if (this.config.urlParams) {
      extraParamsString = $.param(this.config.urlParams);
      url = url + "?" + extraParamsString;
    }
    return url;
  };

  RestArrayStore.prototype._ajax = function(type, id, data, success, error) {
    var options;
    options = $.extend(this.ajaxConfig, {
      url: this._request_url(type, id),
      type: type,
      data: data,
      success: (function(_this) {
        return function(data, textStatus, jqXHR) {
          if (typeof success === "function") {
            success(data);
          }
          return setTimeout((function() {
            return _this.dataFetchLock = false;
          }), 50);
        };
      })(this),
      error: (function(_this) {
        return function(jqXHR, textStatus, errorThrown) {
          if (typeof error === "function") {
            error(jqXHR.responseJSON);
          }
          return _this.dataFetchLock = false;
        };
      })(this)
    });
    this.dataFetchLock = true;
    return $.ajax(options);
  };

  RestArrayStore.prototype._sync_with_data_objects = function(objects) {
    var addObjectIds, dataObjectIds, i, id, j, k, l, len, len1, len2, len3, o, objectIds, objectsMap, removeDataObjectIds, results, updateDataObjectIds;
    if (objects.length === 0) {
      return this._reset_data();
    }
    if (this._data.length === 0) {
      return (function() {
        var i, len, results;
        results = [];
        for (i = 0, len = objects.length; i < len; i++) {
          o = objects[i];
          results.push(this._add_data_object(o));
        }
        return results;
      }).call(this);
    }
    objectsMap = {};
    for (i = 0, len = objects.length; i < len; i++) {
      o = objects[i];
      o = this._normalize_object_id(o);
      objectsMap[o._id] = o;
    }
    objectIds = $.map(objects, function(o) {
      return o._id;
    });
    dataObjectIds = $.map(this._data, function(o) {
      return o._id;
    });
    addObjectIds = $(objectIds).not(dataObjectIds).get();
    updateDataObjectIds = $(objectIds).not(addObjectIds).get();
    removeDataObjectIds = $(dataObjectIds).not(objectIds).get();
    for (j = 0, len1 = removeDataObjectIds.length; j < len1; j++) {
      id = removeDataObjectIds[j];
      this._remove_data_object(id);
    }
    for (k = 0, len2 = addObjectIds.length; k < len2; k++) {
      id = addObjectIds[k];
      this._add_data_object(objectsMap[id]);
    }
    results = [];
    for (l = 0, len3 = updateDataObjectIds.length; l < len3; l++) {
      id = updateDataObjectIds[l];
      results.push(this._update_data_object(id, objectsMap[id]));
    }
    return results;
  };

  RestArrayStore.prototype._update_next_page = function(data) {
    if (this.pagination) {
      if (data.length > 0) {
        this.lastPageLoaded = true;
        if (data.length === this.objectsPerPage) {
          this.nextPage += 1;
          return this.lastPageLoaded = false;
        }
      } else {
        return this.lastPageLoaded = true;
      }
    }
  };

  RestArrayStore.prototype._is_pagination_edge_case = function() {
    return this.pagination && this.lastPageLoaded === false;
  };

  RestArrayStore.prototype._reload_current_page = function(callbacks) {
    this.nextPage -= 1;
    return this.load(true, callbacks);
  };

  RestArrayStore.prototype.loadObject = function(id, callbacks) {
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    return this._ajax('GET', id, {}, ((function(_this) {
      return function(data) {
        return callbacks.onSuccess(data);
      };
    })(this)), callbacks.onError);
  };

  RestArrayStore.prototype.load = function(sync, callbacks) {
    var params;
    if (sync == null) {
      sync = false;
    }
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    params = {};
    if (this.pagination) {
      params[this.requestParams.page] = this.nextPage;
      params[this.requestParams.perPage] = this.objectsPerPage;
    }
    if (this.searchable && this.searchQuery.length > 0) {
      params[this.requestParams.search] = this.searchQuery;
    }
    params = $.param(params);
    return this._ajax('GET', null, params, ((function(_this) {
      return function(data) {
        var i, len, o;
        _this._update_next_page(data);
        if (sync) {
          _this._sync_with_data_objects(data);
        } else {
          for (i = 0, len = data.length; i < len; i++) {
            o = data[i];
            _this._add_data_object(o);
          }
        }
        callbacks.onSuccess(data);
        return $(_this).trigger('objects_added', {
          objects: data
        });
      };
    })(this)), function() {
      return chr.showError('Error while loading data, application error 500.');
    });
  };

  RestArrayStore.prototype.reset = function(searchQuery1) {
    this.searchQuery = searchQuery1 != null ? searchQuery1 : '';
    this.lastPageLoaded = false;
    this.nextPage = 1;
    return this.load(true);
  };

  RestArrayStore.prototype.search = function(searchQuery) {
    return this.reset(searchQuery);
  };

  RestArrayStore.prototype.push = function(serializedFormObject, callbacks) {
    var obj;
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    obj = this._parse_form_object(serializedFormObject);
    return this._ajax('POST', null, obj, ((function(_this) {
      return function(data) {
        var d;
        d = _this._add_data_object(data);
        if (_this._is_pagination_edge_case()) {
          if (d.position >= (_this.nextPage - 1) * _this.objectsPerPage) {
            _this._remove_data_object(d.object._id);
          }
        }
        return callbacks.onSuccess(data);
      };
    })(this)), callbacks.onError);
  };

  RestArrayStore.prototype.update = function(id, serializedFormObject, callbacks) {
    var obj;
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    obj = this._parse_form_object(serializedFormObject);
    return this._ajax('PUT', id, obj, ((function(_this) {
      return function(data) {
        var d;
        d = _this._update_data_object(id, data);
        if (_this._is_pagination_edge_case() && d.positionHasChanged) {
          if (d.position >= (_this.nextPage - 1) * _this.objectsPerPage - 1) {
            return _this._reload_current_page(callbacks);
          }
        } else {
          return callbacks.onSuccess(data);
        }
      };
    })(this)), callbacks.onError);
  };

  RestArrayStore.prototype.remove = function(id, callbacks) {
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    return this._ajax('DELETE', id, {}, ((function(_this) {
      return function() {
        _this._remove_data_object(id);
        if (_this._is_pagination_edge_case()) {
          return _this._reload_current_page(callbacks);
        } else {
          return callbacks.onSuccess();
        }
      };
    })(this)), callbacks.onError);
  };

  return RestArrayStore;

})(ArrayStore);

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.RestObjectStore = (function(superClass) {
  extend(RestObjectStore, superClass);

  function RestObjectStore() {
    return RestObjectStore.__super__.constructor.apply(this, arguments);
  }

  RestObjectStore.prototype._initialize_store = function() {
    this.dataFetchLock = false;
    return this._configure_store();
  };

  RestObjectStore.prototype._configure_store = function() {
    return this.ajaxConfig = {};
  };

  RestObjectStore.prototype._resource_url = function() {
    return this.config.path;
  };

  RestObjectStore.prototype._parse_form_object = function(serializedFormObject) {
    var fieldName, key, object, value;
    object = {};
    for (key in serializedFormObject) {
      value = serializedFormObject[key];
      fieldName = key.replace('[', '').replace(']', '');
      object[fieldName] = value;
    }
    return object;
  };

  RestObjectStore.prototype._ajax = function(type, data, success, error) {
    var options;
    options = $.extend(this.ajaxConfig, {
      url: this._resource_url(),
      type: type,
      data: data,
      success: (function(_this) {
        return function(data, textStatus, jqXHR) {
          if (typeof success === "function") {
            success(data);
          }
          return _this.dataFetchLock = false;
        };
      })(this),
      error: (function(_this) {
        return function(jqXHR, textStatus, errorThrown) {
          if (typeof error === "function") {
            error(jqXHR.responseJSON);
          }
          return _this.dataFetchLock = false;
        };
      })(this)
    });
    this.dataFetchLock = true;
    return $.ajax(options);
  };

  RestObjectStore.prototype.loadObject = function(callbacks) {
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    return this._ajax('GET', null, ((function(_this) {
      return function(data) {
        return callbacks.onSuccess(data);
      };
    })(this)), callbacks.onError);
  };

  RestObjectStore.prototype.update = function(id, serializedFormObject, callbacks) {
    var obj;
    if (callbacks == null) {
      callbacks = {};
    }
    if (callbacks.onSuccess == null) {
      callbacks.onSuccess = $.noop;
    }
    if (callbacks.onError == null) {
      callbacks.onError = $.noop;
    }
    obj = this._parse_form_object(serializedFormObject);
    return this._ajax('PUT', obj, ((function(_this) {
      return function(data) {
        _this._data = data;
        return callbacks.onSuccess(data);
      };
    })(this)), callbacks.onError);
  };

  return RestObjectStore;

})(ObjectStore);

this.railsFormObjectParser = {
  _parse_form_object: function(serializedFormObject) {
    var attr_name, attr_value, formDataObject, i, len, value, values;
    formDataObject = new FormData();
    for (attr_name in serializedFormObject) {
      attr_value = serializedFormObject[attr_name];
      if (attr_name.indexOf('[__LIST__') > -1) {
        attr_name = attr_name.replace('__LIST__', '');
        values = attr_value.split(',');
        for (i = 0, len = values.length; i < len; i++) {
          value = values[i];
          formDataObject.append("" + this.config.resource + attr_name + "[]", value);
        }
      } else {
        if (attr_name.startsWith('__FILE__')) {
          attr_name = attr_name.replace('__FILE__', '');
        }
        formDataObject.append("" + this.config.resource + attr_name, attr_value);
      }
    }
    return formDataObject;
  }
};

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.RailsArrayStore = (function(superClass) {
  extend(RailsArrayStore, superClass);

  function RailsArrayStore() {
    return RailsArrayStore.__super__.constructor.apply(this, arguments);
  }

  RailsArrayStore.prototype._configure_store = function() {
    return this.ajaxConfig = {
      processData: false,
      contentType: false
    };
  };

  RailsArrayStore.prototype._resource_url = function(type, id) {
    var objectPath;
    objectPath = id ? "/" + id : '';
    return "" + this.config.path + objectPath + ".json";
  };

  return RailsArrayStore;

})(RestArrayStore);

include(RailsArrayStore, railsFormObjectParser);

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

this.RailsObjectStore = (function(superClass) {
  extend(RailsObjectStore, superClass);

  function RailsObjectStore() {
    return RailsObjectStore.__super__.constructor.apply(this, arguments);
  }

  RailsObjectStore.prototype._configure_store = function() {
    return this.ajaxConfig = {
      processData: false,
      contentType: false
    };
  };

  RailsObjectStore.prototype._resource_url = function() {
    return this.config.path + ".json";
  };

  return RailsObjectStore;

})(RestObjectStore);

include(RailsObjectStore, railsFormObjectParser);
