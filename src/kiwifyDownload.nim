from std/strformat import fmt
from std/strutils import join, parseInt, strip, AllChars, Digits
from std/os import createDir, `/`, sleep, fileExists
from std/json import parseJson, items, `{}`, getStr, hasKey, `$`
from std/httpclient import newHttpClient, newHttpHeaders, getContent, close
import std/osproc

from pkg/vimeo import parseVimeo
from pkg/util/forTerm import echoSingleLine
from pkg/util/forFs import escapeFs

proc downloadFile(url, dest: string) =
  if fileExists dest:
    echo "Skipping, file exists."
    return

  let cmd = fmt"""wget "{url}" -O "{dest}_tmp" && mv "{dest}_tmp" "{dest}" """
  let down = startProcess(
    cmd,
    options = {poStdErrToStdOut, poUsePath, poEvalCommand, poDaemon}
  )
  for line in down.lines:
    echoSingleLine line
  echo ""
  close down

proc vimeoBestResolution(vimeoId: string): string =
  ## Gets the best resolution video from Vimeo page
  let
    client = newHttpClient(headers = newHttpHeaders({
      "referer": "https://dashboard.kiwify.com.br"
    }))
    vimeoData = parseVimeo client.getContent "https://player.vimeo.com/video/" & vimeoId
  var max: tuple[quality, index: int]
  for i, vid in vimeoData.videos:
    let quality = vid.quality.strip(chars = AllChars - Digits).parseInt
    if quality > max.quality:
      max = (quality, i)
  result = vimeoData.videos[max.index].url

proc kiwifyDownload*(jsonPath, output: string) =
  ## Downloads using wget all videos of Kiwify course
  let
    json = readFile jsonPath
    node = parseJson json

  createDir output

  writeFile(output / "course.json", json)

  var m = 0
  for module in node{"course", "modules"}:
    let
      moduleName = escapeFs(fmt"{m}_" & module{"name"}.getStr)
      modulePath = output / moduleName
    createDir modulePath
    writeFile(modulePath / "module.json", $module)
    echo "Module '", moduleName, "'"
    var l = 0
    for lesson in module{"lessons"}:
      let
        lessonName = escapeFs(fmt"{l}_" & lesson{"title"}.getStr)
        lessonPath = modulePath / lessonName
      createDir lessonPath
      writeFile(lessonPath / "lesson.json", $lesson)
      if lesson.hasKey "video":
        echo "  Starting download of '", lessonName, "' video and thumbnail"
        downloadFile(lesson{"video", "external_id"}.getStr.vimeoBestResolution, lessonPath / lesson{"video", "name"}.getStr)
        let thumb = lesson{"video", "thumbnail"}.getStr
        if thumb.len > 0:
          downloadFile(thumb, lessonPath / "thumbnail.png")
      else:
        writeFile(lessonPath / "content.html", lesson{"content"}.getStr)

      inc l
    inc m

when isMainModule:
  import pkg/cligen
  dispatch kiwifyDownload
