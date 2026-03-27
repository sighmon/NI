jQuery(document).ready ->
  widgets = $(".newsletter-subscription[data-status-url]")
  return unless widgets.length

  csrfToken = $('meta[name="csrf-token"]').attr("content")

  widgets.each ->
    container = $(this)
    button = container.find(".js-newsletter-toggle")
    message = container.find(".js-newsletter-subscription-message")

    setState = (subscribed) ->
      container.attr("data-subscribed", subscribed)
      if subscribed
        button
          .removeClass("btn-success btn-outline-secondary")
          .addClass("btn-danger")
          .text("Unsubscribe from email newsletter")
      else
        button
          .removeClass("btn-danger btn-outline-secondary")
          .addClass("btn-success")
          .text("Subscribe to email newsletter")

    setLoading = (label) ->
      button
        .prop("disabled", true)
        .removeClass("btn-success btn-danger")
        .addClass("btn-outline-secondary")
        .text(label)

    updateMessage = (text, isError = false) ->
      message
        .text(text || "")
        .toggleClass("text-danger", isError)
        .toggleClass("text-muted", !isError)

    request = (method, url) ->
      $.ajax(
        url: url
        method: method
        dataType: "json"
        headers:
          "X-CSRF-Token": csrfToken
      )

    loadStatus = ->
      setLoading("Checking newsletter status...")
      request("GET", container.data("status-url"))
        .done (data) ->
          setState(!!data.subscribed)
          button.prop("disabled", false)
          updateMessage(data.message)
        .fail ->
          setLoading("Newsletter status unavailable")
          # updateMessage("We could not load your newsletter status right now.", true)

    button.on "click", (event) ->
      event.preventDefault()
      return if button.prop("disabled")

      subscribed = String(container.attr("data-subscribed")) == "true"
      method = if subscribed then "DELETE" else "POST"
      url = if subscribed then container.data("unsubscribe-url") else container.data("subscribe-url")
      pendingLabel = if subscribed then "Unsubscribing..." else "Subscribing..."

      setLoading(pendingLabel)

      request(method, url)
        .done (data) ->
          setState(!!data.subscribed)
          button.prop("disabled", false)
          updateMessage(data.message)
        .fail ->
          loadStatus()
          updateMessage("We could not update your newsletter preference right now.", true)

    loadStatus()
