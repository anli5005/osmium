logFile = "/osmium/osmium.log"
stream = nil
logToTerminal = false

function setup()
  stream = fs.open(logFile, "a")
end

logsUntilSave = 3

function save()
  stream.flush()
  logsUntilSave = 3
end

function log(message)
  if logToTerminal then
    print(message)
  end
  stream.writeLine(message)
  logsUntilSave = logsUntilSave - 1
  if logsUntilSave < 1 then
    save()
  end
end
