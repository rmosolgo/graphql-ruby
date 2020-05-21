// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require rails-ujs
// Action Cable provides the framework to deal with WebSockets in Rails.
// You can generate new channels where WebSocket features live using the `rails generate channel` command.
//
//= require action_cable
//= require_self

(function() {
  this.App || (this.App = {});

  App.cable = ActionCable.createConsumer();

  App.subscribe = function(options) {
    var query = options.query
    var variables = options.variables
    var receivedCallback = options.received
    // Unique-ish
    var uuid = Math.round(Date.now() + Math.random() * 100000).toString(16)
    return {
      subscription: App.cable.subscriptions.create({
          channel: "GraphqlChannel",
          id: uuid,
        }, {
          connected: function() {
            this.perform("execute", {
              query: query,
              variables: variables,
            })
            console.log("Connected", query, variables)
          },
          received: function(data) {
            console.log("received", query, variables, data)
            receivedCallback(data)
          }
        }
      ),
      trigger: function(options) {
        this.subscription.perform("make_trigger", options)
      },
      unsubscribe: function() {
        this.subscription.unsubscribe()
      },
    }
  }
}).call(this);
