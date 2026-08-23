.pragma library

function parseStatus(raw) {
  try {
    var data = JSON.parse(String(raw || "").trim().split("\n").pop())
    return {
      ok: true,
      connected: data.connected === true,
      addr: data.addr || "",
      name: data.name || "",
      strategy: data.strategy || "",
      fanDuty: data.fan_duty === null || data.fan_duty === undefined ? null : Number(data.fan_duty),
      version: data.version || ""
    }
  } catch (e) {
    return { ok: false, connected: false, addr: "", name: "", strategy: "", fanDuty: null, version: "" }
  }
}

function parseFillLine(raw) {
  try {
    return JSON.parse(String(raw || "").trim())
  } catch (e) {
    return null
  }
}

function fillProgress(event) {
  if (!event || event.event !== "pulse") return 0
  var n = Number(event.n) || 8
  var i = Number(event.i) || 0
  var on = event.phase === "on"
  var done = (i - 1) + (on ? 0.5 : 1)
  return Math.max(0, Math.min(1, done / n))
}

function strategyLabel(id) {
  if (id === "quieter") return "Quieter"
  if (id === "quiet") return "Quiet"
  if (id === "balanced") return "Balanced"
  if (id === "max") return "Max"
  if (id === "smart") return "Smart"
  return "Not set"
}

function profiles() {
  return ["smart", "quieter", "quiet", "balanced", "max"]
}
