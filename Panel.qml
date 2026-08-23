import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "shi1xin.mrcc"
  ipcTarget: "shi1xin.mrcc"

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root
  property bool openedFromHotkey: false

  property bool mrccFound: false
  property bool connected: false
  property string addr: ""
  property string deviceName: ""
  property string strategy: ""
  property var fanDuty: null
  property string lastError: ""
  property bool busy: false
  property bool filling: false
  property real fillFraction: 0
  property string fillText: ""
  property bool sessionHookInstalled: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool locked: busy || filling
  readonly property var profileIds: Model.profiles()

  function open() {
    openedFromHotkey = false
    root.controller.show()
    refresh()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    refresh()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function refresh() {
    if (statusProc.running) return
    statusProc.running = true
  }

  function runMrcc(args) {
    if (locked) return
    lastError = ""
    busy = true
    actionProc.command = ["bash", "-c", "PATH=\"$HOME/.cargo/bin:$PATH\"; exec mrcc " + args]
    actionProc.running = true
  }

  function connectCooler() {
    runMrcc("connect")
  }

  function disconnectCooler() {
    if (filling) return
    lastError = ""
    busy = true
    actionProc.command = ["bash", "-c", "PATH=\"$HOME/.cargo/bin:$PATH\"; exec mrcc disconnect"]
    actionProc.running = true
  }

  function toggleConnection() {
    if (locked) return
    if (connected) disconnectCooler()
    else connectCooler()
  }

  function applyProfile(id) {
    if (!connected || locked) return
    runMrcc("strategy " + id)
  }

  function startFill() {
    if (!connected || locked) return
    lastError = ""
    filling = true
    fillFraction = 0
    fillText = "Starting fill-water"
    fillProc.command = ["bash", "-c", "PATH=\"$HOME/.cargo/bin:$PATH\"; exec mrcc fill-water --json"]
    fillProc.running = true
  }

  function onFillLine(line) {
    var ev = Model.parseFillLine(line)
    if (!ev) return
    if (ev.event === "start") {
      fillText = "Filling…"
      fillFraction = 0
    } else if (ev.event === "pulse") {
      fillFraction = Model.fillProgress(ev)
      fillText = "Pulse " + ev.i + "/" + ev.n + " " + ev.phase
    } else if (ev.event === "done") {
      filling = false
      fillFraction = ev.ok ? 1 : fillFraction
      fillText = ev.ok ? "Fill-water done" : (ev.error || "Fill-water failed")
      if (!ev.ok) lastError = ev.error || "Fill-water failed"
      refresh()
    }
  }

  function applyStatus(raw) {
    var st = Model.parseStatus(raw)
    if (!st.ok) {
      lastError = "Could not read mrcc status"
      return
    }
    connected = st.connected
    addr = st.addr
    deviceName = st.name
    strategy = st.strategy
    fanDuty = st.fanDuty
    lastError = ""
  }

  Timer {
    interval: 4000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Component.onCompleted: {
    if (!sessionProc.running) sessionProc.running = true
  }

  Process {
    id: statusProc
    running: false
    command: ["bash", "-c", "PATH=\"$HOME/.cargo/bin:$PATH\"; command -v mrcc >/dev/null || { echo MISSING; exit 2; }; mrcc status --json"]
    stdout: StdioCollector { id: statusOut; waitForEnd: true }
    stderr: StdioCollector { id: statusErr; waitForEnd: true }
    onExited: function(code) {
      var out = String(statusOut.text || "")
      if (code === 2 || out.indexOf("MISSING") === 0) {
        root.mrccFound = false
        return
      }
      root.mrccFound = true
      if (code === 0) root.applyStatus(out)
      else root.lastError = String(statusErr.text || out || "mrcc status failed").trim()
    }
  }

  Process {
    id: actionProc
    running: false
    command: []
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function(code) {
      root.busy = false
      if (code !== 0) root.lastError = String(actionErr.text || "mrcc failed").trim()
      root.refresh()
    }
  }

  Process {
    id: fillProc
    running: false
    command: []
    stdout: SplitParser { onRead: function(line) { root.onFillLine(line) } }
    stderr: StdioCollector { id: fillErr; waitForEnd: true }
    onExited: function(code) {
      root.filling = false
      root.busy = false
      if (code !== 0 && root.lastError === "")
        root.lastError = String(fillErr.text || "fill-water failed").trim()
      root.refresh()
    }
  }

  Process {
    id: sessionProc
    running: false
    command: ["bash", Qt.resolvedUrl("install-session.sh").toString().replace("file://", "")]
    onExited: function(code) { root.sessionHookInstalled = code === 0 }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Column {
          id: column
          width: parent.width
          spacing: Style.space(12)

          PanelHero {
            width: parent.width
            title: "Liquid Cooler"
            meta: !root.mrccFound ? "mrcc not installed" : (root.connected ? "Connected" : "Disconnected")
            detail: {
              if (!root.mrccFound) return "cargo install --git https://github.com/Shi1xin/mrcc.git --locked"
              if (root.deviceName || root.addr) return [root.deviceName, root.addr].filter(function(s) { return s }).join(" · ")
              return "Scan and connect from here"
            }
            foreground: root.foreground
            fontFamily: root.fontFamily
            iconOpacity: root.connected ? 1 : 0.45
            iconComponent: Component {
              Text {
                text: root.connected ? "󰈐" : "󰠝"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.display
              }
            }
            trailingControl: Component {
              ToggleSwitch {
                visible: root.mrccFound
                checked: root.connected
                busy: root.locked
                foreground: root.foreground
                onToggled: {
                  if (root.connected) root.disconnectCooler()
                  else root.connectCooler()
                }
              }
            }
          }

          Text {
            visible: root.lastError !== ""
            width: parent.width
            text: root.lastError
            color: bar && bar.urgent ? bar.urgent : Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          PanelSeparator { visible: root.mrccFound; foreground: root.foreground }

          Column {
            visible: root.mrccFound
            width: parent.width
            spacing: Style.space(8)
            enabled: root.connected && !root.locked
            opacity: enabled ? 1 : 0.4

            PanelSectionHeader {
              text: "STRATEGY"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Flow {
              width: parent.width
              spacing: Style.space(6)
              Repeater {
                model: root.profileIds
                Button {
                  text: Model.strategyLabel(modelData)
                  selected: root.strategy === modelData
                  enabled: root.connected && !root.locked
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  onClicked: root.applyProfile(modelData)
                }
              }
            }
          }

          PanelSeparator { visible: root.mrccFound; foreground: root.foreground }

          Column {
            visible: root.mrccFound
            width: parent.width
            spacing: Style.space(8)

            Button {
              width: parent.width
              text: root.filling ? root.fillText : "Fill water"
              enabled: root.connected && !root.busy && !root.filling
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: root.startFill()
            }

            Rectangle {
              visible: root.filling || root.fillFraction > 0
              width: parent.width
              height: Style.space(6)
              radius: height / 2
              color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.15)
              Rectangle {
                height: parent.height
                width: parent.width * root.fillFraction
                radius: parent.radius
                color: root.foreground
              }
            }
          }
        }
      }
    }
  }
}
