logFile = "/osmium/osmium.log"
stream = nil
logToTerminal = false

function setup()
  local writeStream = fs.open(logFile, "w")
  writeStream.write("")
  writeStream.close()

  stream = fs.open(logFile, "a")
end

logsUntilSave = 5

function save()
  stream.flush()
  logsUntilSave = 5
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
