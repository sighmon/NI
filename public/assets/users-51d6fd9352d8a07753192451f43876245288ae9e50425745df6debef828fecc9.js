(function() {
  jQuery(document).ready(function() {
    var csrfToken, widgets;
    widgets = $(".newsletter-subscription[data-status-url]");
    if (!widgets.length) {
      return;
    }
    csrfToken = $('meta[name="csrf-token"]').attr("content");
    return widgets.each(function() {
      var button, container, loadStatus, message, request, setLoading, setState, setUnavailableState, updateMessage;
      container = $(this);
      button = container.find(".js-newsletter-toggle");
      message = container.find(".js-newsletter-subscription-message");
      setState = function(subscribed) {
        container.attr("data-subscribed", subscribed);
        if (subscribed) {
          return button.removeClass("btn-success btn-outline-secondary").addClass("btn-danger").text("Unsubscribe from email newsletter");
        } else {
          return button.removeClass("btn-danger btn-outline-secondary").addClass("btn-success").text("Subscribe to email newsletter");
        }
      };
      setUnavailableState = function() {
        container.attr("data-subscribed", "unknown");
        return button.prop("disabled", true).removeClass("btn-success btn-danger").addClass("btn-outline-secondary").text("Newsletter status unavailable");
      };
      setLoading = function(label) {
        return button.prop("disabled", true).removeClass("btn-success btn-danger").addClass("btn-outline-secondary").text(label);
      };
      updateMessage = function(text, isError) {
        if (isError == null) {
          isError = false;
        }
        return message.text(text || "").toggleClass("text-danger", isError).toggleClass("text-muted", !isError);
      };
      request = function(method, url) {
        return $.ajax({
          url: url,
          method: method,
          dataType: "json",
          headers: {
            "X-CSRF-Token": csrfToken
          }
        });
      };
      loadStatus = function(failureMessage) {
        if (failureMessage == null) {
          failureMessage = "We could not load your newsletter status right now.";
        }
        setLoading("Checking newsletter status...");
        return request("GET", container.data("status-url")).done(function(data) {
          setState(!!data.subscribed);
          button.prop("disabled", false);
          return updateMessage(data.message);
        }).fail(function() {
          setUnavailableState();
          return updateMessage(failureMessage, true);
        });
      };
      button.on("click", function(event) {
        var method, pendingLabel, subscribed, url;
        event.preventDefault();
        if (button.prop("disabled")) {
          return;
        }
        subscribed = String(container.attr("data-subscribed")) === "true";
        method = subscribed ? "DELETE" : "POST";
        url = subscribed ? container.data("unsubscribe-url") : container.data("subscribe-url");
        pendingLabel = subscribed ? "Unsubscribing..." : "Subscribing...";
        setLoading(pendingLabel);
        return request(method, url).done(function(data) {
          setState(!!data.subscribed);
          button.prop("disabled", false);
          return updateMessage(data.message);
        }).fail(function() {
          return loadStatus("We could not update your newsletter preference right now.");
        });
      });
      return loadStatus();
    });
  });

}).call(this);
