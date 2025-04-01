function detectTheme() {
  var storedTheme = localStorage.getItem("graphql_dashboard:theme")
  var preferredTheme = !!window.matchMedia('(prefers-color-scheme: dark)').matches ? "dark" : "light"
  setTheme(storedTheme || preferredTheme)
}

function toggleTheme() {
  var nextTheme = document.documentElement.getAttribute("data-bs-theme") == "dark" ? "light" : "dark"
  setTheme(nextTheme)
}

function setTheme(theme) {
  localStorage.setItem("graphql_dashboard:theme", theme)
  document.documentElement.setAttribute("data-bs-theme", theme)
  var icon = theme == "dark" ? "🌙" : "🌞"
  var toggle = document.getElementById("themeToggle")
  if (toggle) {
    toggle.innerText = icon
  } else {
    document.addEventListener("DOMContentLoaded", function(_ev) {
      document.getElementById("themeToggle").innerText = icon
    })
  }
}

detectTheme()

var perfettoUrl = "https://ui.perfetto.dev"
async function openOnPerfetto(operationName, tracePath) {
  var resp = await fetch(tracePath);
  var blob = await resp.blob();
  var nextPerfettoData = await blob.arrayBuffer();
  nextPerfettoWindow = window.open(perfettoUrl)

  var messageHandler = function(event) {
    if (event.origin == perfettoUrl && event.data == "PONG") {
      clearInterval(perfettoWaiting)
      window.removeEventListener("message", messageHandler)
      nextPerfettoWindow.postMessage({
        perfetto: {
          buffer: nextPerfettoData,
          title: operationName + " - GraphQL",
          filename: "perfetto-" + operationName + ".dump",
        }
      }, perfettoUrl)
    }
  }

  window.addEventListener("message", messageHandler, false)
  perfettoWaiting = setInterval(function() {
    nextPerfettoWindow.postMessage("PING", perfettoUrl)
  }, 100)
}

function getCsrfToken() {
  return document.querySelector("meta[name='csrf-token']").content
}

function deleteTrace(tracePath) {
  if (confirm("Are you sure you want to permanently delete this trace?")) {
    fetch(tracePath, { method: "DELETE", headers: {
      "X-CSRF-Token": getCsrfToken()
    } }).then(function(_response) {
      window.location.reload()
    })
  }
}

function deleteAllTraces(path) {
  if (confirm("Are you sure you want to permanently delete ALL traces?")) {
    fetch(path, { method: "DELETE", headers: {
      "X-CSRF-Token": getCsrfToken()
    } }).then(function(_response) {
      window.location.reload()
    })
  }
}

function deleteAllSubscriptions(path) {
  if (confirm("This will:\n\n- Remove all subscriptions from the database\n- Stop updates to all current subscribers\n\nAre you sure?")) {
    fetch(path, { method: "POST", headers: {
      "X-CSRF-Token": getCsrfToken()
    } }).then(function(_response) {
      window.location.reload()
    })
  }
}

function sendArchive(clientName) {
  var values = []
  document.querySelectorAll(".archive-check:checked").forEach(function(el) {
    values.push(el.value)
  })
  if (values.length == 0) {
    return
  }
  var mode = window.location.pathname.includes("/archived") ? "/unarchive" : "/archive"
  if (mode == "/archive") {
    if (!confirm("Are you sure you want to archive these operations? They won't be usable by clients while archived.")) {
      return
    }
  } else {
    if (!confirm("Are you sure you want to reactivate these operations? They'll be available to clients again.")) {
      return
    }
  }
  var url = window.location.pathname.replace("/archived", "")
  url += mode
  var data

  if (clientName) {
    data = {
      operation_aliases: values
    }
  } else {
    data = {
      digests: values
    }
  }
  fetch(url, { method: "POST", body: JSON.stringify(data), headers: {
    "X-CSRF-Token": getCsrfToken(),
    "Content-Type": "application/json",
  }}).then(function(_response) {
    window.location.reload()
  })
}

document.addEventListener("click", function(event) {
  var dataset = event.target.dataset
  if (dataset.perfettoOpen) {
    openOnPerfetto(dataset.perfettoOpen, dataset.perfettoPath)
  } else if (dataset.perfettoDelete) {
    deleteTrace(dataset.perfettoDelete, event)
  } else if (dataset.perfettoDeleteAll) {
    deleteAllTraces(dataset.perfettoDeleteAll)
  } else if (dataset.subscriptionsDeleteAll) {
    deleteAllSubscriptions(dataset.subscriptionsDeleteAll)
  } else if (event.target.id == "themeToggle") {
    toggleTheme()
  } else if (dataset.archiveClient || dataset.archiveAll) {
    sendArchive(dataset.archiveClient)
  }
})
