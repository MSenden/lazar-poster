-- 
-- Copyright (C) 2009-2016 John MacFarlane, Hans Hagen
-- 
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included
-- in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- 
-- Copyright (C) 2016 Vít Novotný
-- 
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3
-- of this license or (at your option) any later version.
-- The latest version of this license is in
-- 
--     http://www.latex-project.org/lppl.txt
-- 
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
-- 
-- This work has the LPPL maintenance status `maintained'.
-- The Current Maintainer of this work is Vít Novotný.
-- 
-- Send bug reports, requests for additions and questions
-- either to the GitHub issue tracker at
-- 
--     https://github.com/witiko/markdown/issues
-- 
-- or to the e-mail address <witiko@mail.muni.cz>.
-- 
-- MODIFICATION ADVICE:
-- 
-- If you want to customize this file, it is best to make a copy of
-- the source file(s) from which it was produced. Use a different
-- name for your copy(ies) and modify the copy(ies); this will ensure
-- that your modifications do not get overwritten when you install a
-- new release of the standard system. You should also ensure that
-- your modified source file does not generate any modified file with
-- the same name as a standard file.
-- 
-- You will also need to produce your own, suitably named, .ins file to
-- control the generation of files from your source file; this file
-- should contain your own preambles for the files it generates, not
-- those in the standard .ins files.
-- 
local metadata = {
    version   = "2.1.3",
    comment   = "A module for the conversion from markdown to plain TeX",
    author    = "John MacFarlane, Hans Hagen, Vít Novotný",
    copyright = "2009-2016 John MacFarlane, Hans Hagen; 2016 Vít Novotný",
    license   = "LPPL 1.3"
}
if not modules then modules = { } end
modules['markdown'] = metadata
local lpeg = require("lpeg")
local unicode = require("unicode")
local md5 = require("md5")
local M = {}
local defaultOptions = {}
defaultOptions.blankBeforeBlockquote = false
defaultOptions.blankBeforeCodeFence = false
defaultOptions.blankBeforeHeading = false
defaultOptions.cacheDir = "."
defaultOptions.citationNbsps = true
defaultOptions.citations = false
defaultOptions.definitionLists = false
defaultOptions.hashEnumerators = false
defaultOptions.hybrid = false
defaultOptions.fencedCode = false
defaultOptions.footnotes = false
defaultOptions.preserveTabs = false
defaultOptions.smartEllipses = false
defaultOptions.startNumber = true
defaultOptions.tightLists = true
local upper, gsub, format, length =
  string.upper, string.gsub, string.format, string.len
local concat = table.concat
local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs, any =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs, lpeg.P(1)
local util = {}
function util.err(msg, exit_code)
  io.stderr:write("markdown.lua: " .. msg .. "\n")
  os.exit(exit_code or 1)
end
function util.cache(dir, string, salt, transform, suffix)
  local digest = md5.sumhexa(string .. (salt or ""))
  local name = util.pathname(dir, digest .. suffix)
  local file = io.open(name, "r")
  if file == nil then -- If no cache entry exists, then create a new one.
    local file = assert(io.open(name, "w"))
    local result = string
    if transform ~= nil then
      result = transform(result)
    end
    assert(file:write(result))
    assert(file:close())
  end
  return name
end
function util.table_copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end
function util.expand_tabs_in_line(s, tabstop)
  local tab = tabstop or 4
  local corr = 0
  return (s:gsub("()\t", function(p)
            local sp = tab - (p - 1 + corr) % tab
            corr = corr - 1 + sp
            return string.rep(" ", sp)
          end))
end
function util.walk(t, f)
  local typ = type(t)
  if typ == "string" then
    f(t)
  elseif typ == "table" then
    local i = 1
    local n
    n = t[i]
    while n do
      util.walk(n, f)
      i = i + 1
      n = t[i]
    end
  elseif typ == "function" then
    local ok, val = pcall(t)
    if ok then
      util.walk(val,f)
    end
  else
    f(tostring(t))
  end
end
function util.flatten(ary)
  local new = {}
  for _,v in ipairs(ary) do
    if type(v) == "table" then
      for _,w in ipairs(util.flatten(v)) do
        new[#new + 1] = w
      end
    else
      new[#new + 1] = v
    end
  end
  return new
end
function util.rope_to_string(rope)
  local buffer = {}
  util.walk(rope, function(x) buffer[#buffer + 1] = x end)
  return table.concat(buffer)
end
function util.rope_last(rope)
  if #rope == 0 then
    return nil
  else
    local l = rope[#rope]
    if type(l) == "table" then
      return util.rope_last(l)
    else
      return l
    end
  end
end
function util.intersperse(ary, x)
  local new = {}
  local l = #ary
  for i,v in ipairs(ary) do
    local n = #new
    new[n + 1] = v
    if i ~= l then
      new[n + 2] = x
    end
  end
  return new
end
function util.map(ary, f)
  local new = {}
  for i,v in ipairs(ary) do
    new[i] = f(v)
  end
  return new
end
function util.escaper(char_escapes, string_escapes)
  local char_escapes_list = ""
  for i,_ in pairs(char_escapes) do
    char_escapes_list = char_escapes_list .. i
  end
  local escapable = S(char_escapes_list) / char_escapes
  if string_escapes then
    for k,v in pairs(string_escapes) do
      escapable = P(k) / v + escapable
    end
  end
  local escape_string = Cs((escapable + any)^0)
  return function(s)
    return lpeg.match(escape_string, s)
  end
end
function util.pathname(dir, file)
  if #dir == 0 then
    return file
  else
    return dir .. "/" .. file
  end
end
M.writer = {}
function M.writer.new(options)
  local self = {}
  options = options or {}
  setmetatable(options, { __index = function (_, key)
    return defaultOptions[key] end })
  self.suffix = ".tex"
  self.space = " "
  self.nbsp = "\\markdownRendererNbsp{}"
  function self.plain(s)
    return s
  end
  function self.paragraph(s)
    return s
  end
  function self.pack(name)
    return [[\input"]] .. name .. [["\relax]]
  end
  self.interblocksep = "\\markdownRendererInterblockSeparator\n{}"
  self.eof = [[\relax]]
  self.linebreak = "\\markdownRendererLineBreak\n{}"
  self.ellipsis = "\\markdownRendererEllipsis{}"
  self.hrule = "\\markdownRendererHorizontalRule{}"
  local escaped_chars = {
     ["{"] = "\\markdownRendererLeftBrace{}",
     ["}"] = "\\markdownRendererRightBrace{}",
     ["$"] = "\\markdownRendererDollarSign{}",
     ["%"] = "\\markdownRendererPercentSign{}",
     ["&"] = "\\markdownRendererAmpersand{}",
     ["_"] = "\\markdownRendererUnderscore{}",
     ["#"] = "\\markdownRendererHash{}",
     ["^"] = "\\markdownRendererCircumflex{}",
     ["\\"] = "\\markdownRendererBackslash{}",
     ["~"] = "\\markdownRendererTilde{}",
     ["|"] = "\\markdownRendererPipe{}", }
   local escaped_minimal_chars = {
     ["{"] = "\\markdownRendererLeftBrace{}",
     ["}"] = "\\markdownRendererRightBrace{}",
     ["%"] = "\\markdownRendererPercentSign{}",
     ["\\"] = "\\markdownRendererBackslash{}", }
   local escaped_minimal_strings = {
     ["^^"] = "\\markdownRendererCircumflex\\markdownRendererCircumflex ", }
  local escape = util.escaper(escaped_chars)
  local escape_minimal = util.escaper(escaped_minimal_chars,
    escaped_minimal_strings)
  if options.hybrid then
    self.string = function(s) return s end
    self.uri = function(u) return u end
  else
    self.string = escape
    self.uri = escape_minimal
  end
  function self.code(s)
    return {"\\markdownRendererCodeSpan{",escape(s),"}"}
  end
  function self.link(lab,src,tit)
    return {"\\markdownRendererLink{",lab,"}",
                          "{",self.string(src),"}",
                          "{",self.uri(src),"}",
                          "{",self.string(tit or ""),"}"}
  end
  function self.image(lab,src,tit)
    return {"\\markdownRendererImage{",lab,"}",
                           "{",self.string(src),"}",
                           "{",self.uri(src),"}",
                           "{",self.string(tit or ""),"}"}
  end
  local function ulitem(s)
    return {"\\markdownRendererUlItem ",s,
            "\\markdownRendererUlItemEnd "}
  end

  function self.bulletlist(items,tight)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = ulitem(item)
    end
    local contents = util.intersperse(buffer,"\n")
    if tight and options.tightLists then
      return {"\\markdownRendererUlBeginTight\n",contents,
        "\n\\markdownRendererUlEndTight "}
    else
      return {"\\markdownRendererUlBegin\n",contents,
        "\n\\markdownRendererUlEnd "}
    end
  end
  local function olitem(s,num)
    if num ~= nil then
      return {"\\markdownRendererOlItemWithNumber{",num,"}",s,
              "\\markdownRendererOlItemEnd "}
    else
      return {"\\markdownRendererOlItem ",s,
              "\\markdownRendererOlItemEnd "}
    end
  end

  function self.orderedlist(items,tight,startnum)
    local buffer = {}
    local num = startnum
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = olitem(item,num)
      if num ~= nil then
        num = num + 1
      end
    end
    local contents = util.intersperse(buffer,"\n")
    if tight and options.tightLists then
      return {"\\markdownRendererOlBeginTight\n",contents,
        "\n\\markdownRendererOlEndTight "}
    else
      return {"\\markdownRendererOlBegin\n",contents,
        "\n\\markdownRendererOlEnd "}
    end
  end
  local function dlitem(term, defs)
    local retVal = {"\\markdownRendererDlItem{",term,"}"}
    for _, def in ipairs(defs) do
      retVal[#retVal+1] = {"\\markdownRendererDlDefinitionBegin ",def,
                           "\\markdownRendererDlDefinitionEnd "}
    end
    retVal[#retVal+1] = "\\markdownRendererDlItemEnd "
    return retVal
  end

  function self.definitionlist(items,tight)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = dlitem(item.term, item.definitions)
    end
    if tight and options.tightLists then
      return {"\\markdownRendererDlBeginTight\n", buffer,
        "\n\\markdownRendererDlEndTight"}
    else
      return {"\\markdownRendererDlBegin\n", buffer,
        "\n\\markdownRendererDlEnd"}
    end
  end
  function self.emphasis(s)
    return {"\\markdownRendererEmphasis{",s,"}"}
  end
  function self.strong(s)
    return {"\\markdownRendererStrongEmphasis{",s,"}"}
  end
  function self.blockquote(s)
    return {"\\markdownRendererBlockQuoteBegin\n",s,
      "\n\\markdownRendererBlockQuoteEnd "}
  end
  function self.verbatim(s)
    local name = util.cache(options.cacheDir, s, nil, nil, ".verbatim")
    return {"\\markdownRendererInputVerbatim{",name,"}"}
  end
  function self.fencedCode(i, s)
    local name = util.cache(options.cacheDir, s, nil, nil, ".verbatim")
    return {"\\markdownRendererInputFencedCode{",name,"}{",i,"}"}
  end
  function self.heading(s,level)
    local cmd
    if level == 1 then
      cmd = "\\markdownRendererHeadingOne"
    elseif level == 2 then
      cmd = "\\markdownRendererHeadingTwo"
    elseif level == 3 then
      cmd = "\\markdownRendererHeadingThree"
    elseif level == 4 then
      cmd = "\\markdownRendererHeadingFour"
    elseif level == 5 then
      cmd = "\\markdownRendererHeadingFive"
    elseif level == 6 then
      cmd = "\\markdownRendererHeadingSix"
    else
      cmd = ""
    end
    return {cmd,"{",s,"}"}
  end
  function self.note(s)
    return {"\\markdownRendererFootnote{",s,"}"}
  end
  function self.citations(text_cites, cites)
    local buffer = {"\\markdownRenderer", text_cites and "TextCite" or "Cite",
      "{", #cites, "}"}
    for _,cite in ipairs(cites) do
      buffer[#buffer+1] = {cite.suppress_author and "-" or "+", "{",
        cite.prenote or "", "}{", cite.postnote or "", "}{", cite.name, "}"}
    end
    return buffer
  end

  return self
end
M.reader = {}
function M.reader.new(writer, options)
  local self = {}
  options = options or {}
  setmetatable(options, { __index = function (_, key)
    return defaultOptions[key] end })
  local function normalize_tag(tag)
    return unicode.utf8.lower(
      gsub(util.rope_to_string(tag), "[ \n\r\t]+", " "))
  end
  local expandtabs
  if options.preserveTabs then
    expandtabs = function(s) return s end
  else
    expandtabs = function(s)
                   if s:find("\t") then
                     return s:gsub("[^\n]*", util.expand_tabs_in_line)
                   else
                     return s
                   end
                 end
  end
  local syntax
  local blocks_toplevel
  local blocks
  local inlines, inlines_no_link, inlines_nbsp

  local function create_parser(name, grammar)
    return function(str)
      local res = lpeg.match(grammar(), str)
      if res == nil then
        error(format("%s failed on:\n%s", name, str:sub(1,20)))
      else
        return res
      end
    end
  end

  local parse_blocks = create_parser("parse_blocks",
    function() return blocks end)
  local parse_blocks_toplevel = create_parser("parse_blocks_toplevel",
    function() return blocks_toplevel end)
  local parse_inlines = create_parser("parse_inlines",
    function() return inlines end)
  local parse_inlines_no_link = create_parser("parse_inlines_no_link",
    function() return inlines_no_link end)
  local parse_inlines_nbsp = create_parser("parse_inlines_nbsp",
    function() return inlines_nbsp end)
  local percent                = P("%")
  local at                     = P("@")
  local comma                  = P(",")
  local asterisk               = P("*")
  local dash                   = P("-")
  local plus                   = P("+")
  local underscore             = P("_")
  local period                 = P(".")
  local hash                   = P("#")
  local ampersand              = P("&")
  local backtick               = P("`")
  local less                   = P("<")
  local more                   = P(">")
  local space                  = P(" ")
  local squote                 = P("'")
  local dquote                 = P('"')
  local lparent                = P("(")
  local rparent                = P(")")
  local lbracket               = P("[")
  local rbracket               = P("]")
  local circumflex             = P("^")
  local slash                  = P("/")
  local equal                  = P("=")
  local colon                  = P(":")
  local semicolon              = P(";")
  local exclamation            = P("!")
  local tilde                  = P("~")

  local digit                  = R("09")
  local hexdigit               = R("09","af","AF")
  local letter                 = R("AZ","az")
  local alphanumeric           = R("AZ","az","09")
  local keyword                = letter * alphanumeric^0
  local internal_punctuation   = S(":;,.#$%&-+?<>~/")

  local doubleasterisks        = P("**")
  local doubleunderscores      = P("__")
  local fourspaces             = P("    ")

  local any                    = P(1)
  local fail                   = any - 1
  local always                 = P("")

  local escapable              = S("\\`*_{}[]()+_.!<>#-~:^@;")

  local anyescaped             = P("\\") / "" * escapable
                               + any

  local tab                    = P("\t")
  local spacechar              = S("\t ")
  local spacing                = S(" \n\r\t")
  local newline                = P("\n")
  local nonspacechar           = any - spacing
  local tightblocksep          = P("\001")

  local specialchar            = S("*_`&[]<!\\.@-")

  local normalchar             = any -
                                 (specialchar + spacing + tightblocksep)
  local optionalspace          = spacechar^0
  local eof                    = - any
  local nonindentspace         = space^-3 * - spacechar
  local indent                 = space^-3 * tab
                               + fourspaces / ""
  local linechar               = P(1 - newline)

  local blankline              = optionalspace * newline / "\n"
  local blanklines             = blankline^0
  local skipblanklines         = (optionalspace * newline)^0
  local indentedline           = indent    /"" * C(linechar^1 * newline^-1)
  local optionallyindentedline = indent^-1 /"" * C(linechar^1 * newline^-1)
  local sp                     = spacing^0
  local spnl                   = optionalspace * (newline * optionalspace)^-1
  local line                   = linechar^0 * newline
                               + linechar^1 * eof
  local nonemptyline           = line - blankline

  local chunk = line * (optionallyindentedline - blankline)^0

  -- block followed by 0 or more optionally
  -- indented blocks with first line indented.
  local function indented_blocks(bl)
    return Cs( bl
             * (blankline^1 * indent * -blankline * bl)^0
             * (blankline^1 + eof) )
  end
  local bulletchar = C(plus + asterisk + dash)

  local bullet     = ( Cg(bulletchar, "bulletchar") * #spacing * (tab + space^-3)
                     + space * Cg(bulletchar, "bulletchar") * #spacing * (tab + space^-2)
                     + space * space * Cg(bulletchar, "bulletchar") * #spacing * (tab + space^-1)
                     + space * space * space * Cg(bulletchar, "bulletchar") * #spacing
                     )

  if options.hashEnumerators then
    dig = digit + hash
  else
    dig = digit
  end

  local enumerator = C(dig^3 * period) * #spacing
                   + C(dig^2 * period) * #spacing * (tab + space^1)
                   + C(dig * period) * #spacing * (tab + space^-2)
                   + space * C(dig^2 * period) * #spacing
                   + space * C(dig * period) * #spacing * (tab + space^-1)
                   + space * space * C(dig^1 * period) * #spacing
  local openticks   = Cg(backtick^1, "ticks")

  local function captures_equal_length(s,i,a,b)
    return #a == #b and i
  end

  local closeticks  = space^-1 *
                      Cmt(C(backtick^1) * Cb("ticks"), captures_equal_length)

  local intickschar = (any - S(" \n\r`"))
                    + (newline * -blankline)
                    + (space - closeticks)
                    + (backtick^1 - closeticks)

  local inticks     = openticks * space^-1 * C(intickschar^0) * closeticks
  local function captures_geq_length(s,i,a,b)
    return #a >= #b and i
  end

  local infostring     = (linechar - (backtick + space^1 * (newline + eof)))^0

  local fenceindent
  local function fencehead(char)
    return               C(nonindentspace) / function(s) fenceindent = #s end
                       * Cg(char^3, "fencelength")
                       * optionalspace * C(infostring) * optionalspace
                       * (newline + eof)
  end

  local function fencetail(char)
    return               nonindentspace
                       * Cmt(C(char^3) * Cb("fencelength"),
                             captures_geq_length)
                       * optionalspace * (newline + eof)
                       + eof
  end

  local function fencedline(char)
    return               C(line - fencetail(char))
                       / function(s)
                             return s:gsub("^" .. string.rep(" ?",
                                 fenceindent), "")
                         end
  end
  local leader        = space^-3

  -- in balanced brackets, parentheses, quotes:
  local bracketed     = P{ lbracket
                         * ((anyescaped - (lbracket + rbracket
                             + blankline^2)) + V(1))^0
                         * rbracket }

  local inparens      = P{ lparent
                         * ((anyescaped - (lparent + rparent
                             + blankline^2)) + V(1))^0
                         * rparent }

  local squoted       = P{ squote * alphanumeric
                         * ((anyescaped - (squote + blankline^2))
                             + V(1))^0
                         * squote }

  local dquoted       = P{ dquote * alphanumeric
                         * ((anyescaped - (dquote + blankline^2))
                             + V(1))^0
                         * dquote }

  -- bracketed 'tag' for markdown links, allowing nested brackets:
  local tag           = lbracket
                      * Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped - (rbracket + blankline^2)))^0)
                      * rbracket

  -- url for markdown links, allowing balanced parentheses:
  local url           = less * Cs((anyescaped-more)^0) * more
                      + Cs((inparens + (anyescaped-spacing-rparent))^1)

  -- quoted text possibly with nested quotes:
  local title_s       = squote * Cs(((anyescaped-squote) + squoted)^0) *
                        squote

  local title_d       = dquote * Cs(((anyescaped-dquote) + dquoted)^0) *
                        dquote

  local title_p       = lparent
                      * Cs((inparens + (anyescaped-rparent))^0)
                      * rparent

  local title         = title_d + title_s + title_p

  local optionaltitle = spnl * title * spacechar^0
                      + Cc("")
  local citation_name = Cs(dash^-1) * at
                      * Cs(alphanumeric
                          * (alphanumeric + internal_punctuation
                              - comma - semicolon)^0)

  local citation_body_prenote
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + blankline^2))
                           - (spnl * dash^-1 * at))^0)

  local citation_body_postnote
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + semicolon + blankline^2))
                           - (spnl * rbracket))^0)

  local citation_body_chunk
                      = citation_body_prenote
                      * spnl * citation_name
                      * (comma * spnl)^-1
                      * citation_body_postnote

  local citation_body = citation_body_chunk
                      * (semicolon * spnl * citation_body_chunk)^0

  local citation_headless_body_postnote
                      = Cs((alphanumeric^1
                           + bracketed
                           + inticks
                           + (anyescaped
                               - (rbracket + at + semicolon + blankline^2))
                           - (spnl * rbracket))^0)

  local citation_headless_body
                      = citation_headless_body_postnote
                      * (sp * semicolon * spnl * citation_body_chunk)^0
  local rawnotes = {}

  local function strip_first_char(s)
    return s:sub(2)
  end

  -- like indirect_link
  local function lookup_note(ref)
    return function()
      local found = rawnotes[normalize_tag(ref)]
      if found then
        return writer.note(parse_blocks_toplevel(found))
      else
        return {"[", parse_inlines("^" .. ref), "]"}
      end
    end
  end

  local function register_note(ref,rawnote)
    rawnotes[normalize_tag(ref)] = rawnote
    return ""
  end

  local RawNoteRef = #(lbracket * circumflex) * tag / strip_first_char

  local NoteRef    = RawNoteRef / lookup_note

  local NoteBlock

  if options.footnotes then
    NoteBlock = leader * RawNoteRef * colon * spnl *
                indented_blocks(chunk) / register_note
  else
    NoteBlock = fail
  end
  -- List of references defined in the document
  local references

  -- add a reference to the list
  local function register_link(tag,url,title)
      references[normalize_tag(tag)] = { url = url, title = title }
      return ""
  end

  -- parse a reference definition:  [foo]: /bar "title"
  local define_reference_parser =
    leader * tag * colon * spacechar^0 * url * optionaltitle * blankline^1

  -- lookup link reference and return either
  -- the link or nil and fallback text.
  local function lookup_reference(label,sps,tag)
      local tagpart
      if not tag then
          tag = label
          tagpart = ""
      elseif tag == "" then
          tag = label
          tagpart = "[]"
      else
          tagpart = {"[", parse_inlines(tag), "]"}
      end
      if sps then
        tagpart = {sps, tagpart}
      end
      local r = references[normalize_tag(tag)]
      if r then
        return r
      else
        return nil, {"[", parse_inlines(label), "]", tagpart}
      end
  end

  -- lookup link reference and return a link, if the reference is found,
  -- or a bracketed label otherwise.
  local function indirect_link(label,sps,tag)
    return function()
      local r,fallback = lookup_reference(label,sps,tag)
      if r then
        return writer.link(parse_inlines_no_link(label), r.url, r.title)
      else
        return fallback
      end
    end
  end

  -- lookup image reference and return an image, if the reference is found,
  -- or a bracketed label otherwise.
  local function indirect_image(label,sps,tag)
    return function()
      local r,fallback = lookup_reference(label,sps,tag)
      if r then
        return writer.image(writer.string(label), r.url, r.title)
      else
        return {"!", fallback}
      end
    end
  end
  local bqstart      = more
  local headerstart  = hash
                     + (line * (equal^1 + dash^1) * optionalspace * newline)
  local fencestart   = fencehead(backtick) + fencehead(tilde)

  if options.blankBeforeBlockquote then
    bqstart = fail
  end

  if options.blankBeforeHeading then
    headerstart = fail
  end

  if not options.fencedCode or options.blankBeforeCodeFence then
    fencestart = fail
  end
  local Inline    = V("Inline")

  local Str       = normalchar^1 / writer.string

  local Symbol    = (specialchar - tightblocksep) / writer.string
  local Ellipsis  = P("...") / writer.ellipsis

  local Smart     = Ellipsis
  local Code      = inticks / writer.code
  local Endline   = newline * -( -- newline, but not before...
                        blankline -- paragraph break
                      + tightblocksep  -- nested list
                      + eof       -- end of document
                      + bqstart
                      + headerstart
                      + fencestart
                    ) * spacechar^0 / writer.space

  local Space     = spacechar^2 * Endline / writer.linebreak
                  + spacechar^1 * Endline^-1 * eof / ""
                  + spacechar^1 * Endline^-1 * optionalspace / writer.space

  local NonbreakingEndline
                  = newline * -( -- newline, but not before...
                        blankline -- paragraph break
                      + tightblocksep  -- nested list
                      + eof       -- end of document
                      + bqstart
                      + headerstart
                      + fencestart
                    ) * spacechar^0 / writer.nbsp

  local NonbreakingSpace
                  = spacechar^2 * Endline / writer.linebreak
                  + spacechar^1 * Endline^-1 * eof / ""
                  + spacechar^1 * Endline^-1 * optionalspace / writer.nbsp

  -- parse many p between starter and ender
  local function between(p, starter, ender)
      local ender2 = B(nonspacechar) * ender
      return (starter * #nonspacechar * Ct(p * (p - ender2)^0) * ender2)
  end
  local Strong = ( between(Inline, doubleasterisks, doubleasterisks)
                 + between(Inline, doubleunderscores, doubleunderscores)
                 ) / writer.strong

  local Emph   = ( between(Inline, asterisk, asterisk)
                 + between(Inline, underscore, underscore)
                 ) / writer.emphasis
  local urlchar = anyescaped - newline - more

  local AutoLinkUrl   = less
                      * C(alphanumeric^1 * P("://") * urlchar^1)
                      * more
                      / function(url)
                        return writer.link(writer.string(url), url)
                      end

  local AutoLinkEmail = less
                      * C((alphanumeric + S("-._+"))^1 * P("@") * urlchar^1)
                      * more
                      / function(email)
                        return writer.link(writer.string(email),
                                           "mailto:"..email)
                      end

  local DirectLink    = (tag / parse_inlines_no_link)  -- no links inside links
                      * spnl
                      * lparent
                      * (url + Cc(""))  -- link can be empty [foo]()
                      * optionaltitle
                      * rparent
                      / writer.link

  local IndirectLink = tag * (C(spnl) * tag)^-1 / indirect_link

  -- parse a link or image (direct or indirect)
  local Link          = DirectLink + IndirectLink
  local DirectImage   = exclamation
                      * (tag / parse_inlines)
                      * spnl
                      * lparent
                      * (url + Cc(""))  -- link can be empty [foo]()
                      * optionaltitle
                      * rparent
                      / writer.image

  local IndirectImage  = exclamation * tag * (C(spnl) * tag)^-1 /
                         indirect_image

  local Image         = DirectImage + IndirectImage
  -- avoid parsing long strings of * or _ as emph/strong
  local UlOrStarLine  = asterisk^4 + underscore^4 / writer.string

  local EscapedChar   = S("\\") * C(escapable) / writer.string
  local function citations(text_cites, raw_cites)
      local function normalize(str)
          if str == "" then
              str = nil
          else
              str = (options.citationNbsps and parse_inlines_nbsp or
                parse_inlines)(str)
          end
          return str
      end

      local cites = {}
      for i = 1,#raw_cites,4 do
          cites[#cites+1] = {
              prenote = normalize(raw_cites[i]),
              suppress_author = raw_cites[i+1] == "-",
              name = writer.string(raw_cites[i+2]),
              postnote = normalize(raw_cites[i+3]),
          }
      end
      return writer.citations(text_cites, cites)
  end

  local TextCitations = Ct(Cc("")
                      * citation_name
                      * ((spnl
                           * lbracket
                           * citation_headless_body
                           * rbracket) + Cc(""))) /
                        function(raw_cites)
                            return citations(true, raw_cites)
                        end

  local ParenthesizedCitations
                      = Ct(lbracket
                      * citation_body
                      * rbracket) /
                        function(raw_cites)
                            return citations(false, raw_cites)
                        end

  local Citations     = TextCitations + ParenthesizedCitations
  local Block          = V("Block")

  local Verbatim       = Cs( (blanklines
                           * ((indentedline - blankline))^1)^1
                           ) / expandtabs / writer.verbatim

  local TildeFencedCode
                       = fencehead(tilde)
                       * Cs(fencedline(tilde)^0)
                       * fencetail(tilde)

  local BacktickFencedCode
                       = fencehead(backtick)
                       * Cs(fencedline(backtick)^0)
                       * fencetail(backtick)

  local FencedCode     = (TildeFencedCode + BacktickFencedCode)
                       / function(infostring, code)
                             return writer.fencedCode(
                                 writer.string(infostring),
                                 expandtabs(code))
                         end
  -- strip off leading > and indents, and run through blocks
  local Blockquote     = Cs((
            ((leader * more * space^-1)/"" * linechar^0 * newline)^1
          * (-blankline * linechar^1 * newline)^0
          * (blankline^0 / "")
          )^1) / parse_blocks_toplevel / writer.blockquote

  local function lineof(c)
      return (leader * (P(c) * optionalspace)^3 * (newline * blankline^1
          + newline^-1 * eof))
  end
  local HorizontalRule = ( lineof(asterisk)
                         + lineof(dash)
                         + lineof(underscore)
                         ) / writer.hrule
  local starter = bullet + enumerator

  -- we use \001 as a separator between a tight list item and a
  -- nested list under it.
  local NestedList            = Cs((optionallyindentedline - starter)^1)
                              / function(a) return "\001"..a end

  local ListBlockLine         = optionallyindentedline
                                - blankline - (indent^-1 * starter)

  local ListBlock             = line * ListBlockLine^0

  local ListContinuationBlock = blanklines * (indent / "") * ListBlock

  local function TightListItem(starter)
      return -HorizontalRule
             * (Cs(starter / "" * ListBlock * NestedList^-1) /
                parse_blocks)
             * -(blanklines * indent)
  end

  local function LooseListItem(starter)
      return -HorizontalRule
             * Cs( starter / "" * ListBlock * Cc("\n")
               * (NestedList + ListContinuationBlock^0)
               * (blanklines / "\n\n")
               ) / parse_blocks
  end

  local BulletList = ( Ct(TightListItem(bullet)^1)
                       * Cc(true) * skipblanklines * -bullet
                     + Ct(LooseListItem(bullet)^1)
                       * Cc(false) * skipblanklines ) /
                         writer.bulletlist

  local function orderedlist(items,tight,startNumber)
    if options.startNumber then
      startNumber = tonumber(startNumber) or 1  -- fallback for '#'
    else
      startNumber = nil
    end
    return writer.orderedlist(items,tight,startNumber)
  end

  local OrderedList = Cg(enumerator, "listtype") *
                      ( Ct(TightListItem(Cb("listtype")) *
                           TightListItem(enumerator)^0)
                        * Cc(true) * skipblanklines * -enumerator
                      + Ct(LooseListItem(Cb("listtype")) *
                           LooseListItem(enumerator)^0)
                        * Cc(false) * skipblanklines
                      ) * Cb("listtype") / orderedlist

  local defstartchar = S("~:")
  local defstart     = ( defstartchar * #spacing * (tab + space^-3)
                     + space * defstartchar * #spacing * (tab + space^-2)
                     + space * space * defstartchar * #spacing *
                       (tab + space^-1)
                     + space * space * space * defstartchar * #spacing
                     )

  local dlchunk = Cs(line * (indentedline - blankline)^0)

  local function definition_list_item(term, defs, tight)
    return { term = parse_inlines(term), definitions = defs }
  end

  local DefinitionListItemLoose = C(line) * skipblanklines
                           * Ct((defstart *
                                 indented_blocks(dlchunk) /
                                 parse_blocks_toplevel)^1)
                           * Cc(false)
                           / definition_list_item

  local DefinitionListItemTight = C(line)
                           * Ct((defstart * dlchunk /
                                            parse_blocks)^1)
                           * Cc(true)
                           / definition_list_item

  local DefinitionList =  ( Ct(DefinitionListItemLoose^1) * Cc(false)
                          +  Ct(DefinitionListItemTight^1)
                             * (skipblanklines *
                                -DefinitionListItemLoose * Cc(true))
                          ) / writer.definitionlist
  local Reference      = define_reference_parser / register_link
  local Blank          = blankline / ""
                       + NoteBlock
                       + Reference
                       + (tightblocksep / "\n")
  local Paragraph      = nonindentspace * Ct(Inline^1) * newline
                       * ( blankline^1
                         + #hash
                         + #(leader * more * space^-1)
                         )
                       / writer.paragraph

  local ToplevelParagraph
                       = nonindentspace * Ct(Inline^1) * (newline
                       * ( blankline^1
                         + #hash
                         + #(leader * more * space^-1)
                         + eof
                         )
                       + eof )
                       / writer.paragraph

  local Plain          = nonindentspace * Ct(Inline^1) / writer.plain
  -- parse Atx heading start and return level
  local HeadingStart = #hash * C(hash^-6) * -hash / length

  -- parse setext header ending and return level
  local HeadingLevel = equal^1 * Cc(1) + dash^1 * Cc(2)

  local function strip_atx_end(s)
    return s:gsub("[#%s]*\n$","")
  end

  -- parse atx header
  local AtxHeading = Cg(HeadingStart,"level")
                     * optionalspace
                     * (C(line) / strip_atx_end / parse_inlines)
                     * Cb("level")
                     / writer.heading

  -- parse setext header
  local SetextHeading = #(line * S("=-"))
                     * Ct(line / parse_inlines)
                     * HeadingLevel
                     * optionalspace * newline
                     / writer.heading

  local Heading = AtxHeading + SetextHeading
  syntax =
    { "Blocks",

      Blocks                = Blank^0 *
                              Block^-1 *
                              (Blank^0 / function()
                                return writer.interblocksep
                               end * Block)^0 *
                              Blank^0 *
                              eof,

      Blank                 = Blank,

      Block                 = V("Blockquote")
                            + V("Verbatim")
                            + V("FencedCode")
                            + V("HorizontalRule")
                            + V("BulletList")
                            + V("OrderedList")
                            + V("Heading")
                            + V("DefinitionList")
                            + V("Paragraph")
                            + V("Plain"),

      Blockquote            = Blockquote,
      Verbatim              = Verbatim,
      FencedCode            = FencedCode,
      HorizontalRule        = HorizontalRule,
      BulletList            = BulletList,
      OrderedList           = OrderedList,
      Heading               = Heading,
      DefinitionList        = DefinitionList,
      DisplayHtml           = DisplayHtml,
      Paragraph             = Paragraph,
      Plain                 = Plain,

      Inline                = V("Str")
                            + V("Space")
                            + V("Endline")
                            + V("UlOrStarLine")
                            + V("Strong")
                            + V("Emph")
                            + V("NoteRef")
                            + V("Citations")
                            + V("Link")
                            + V("Image")
                            + V("Code")
                            + V("AutoLinkUrl")
                            + V("AutoLinkEmail")
                            + V("EscapedChar")
                            + V("Smart")
                            + V("Symbol"),

      Str                   = Str,
      Space                 = Space,
      Endline               = Endline,
      UlOrStarLine          = UlOrStarLine,
      Strong                = Strong,
      Emph                  = Emph,
      NoteRef               = NoteRef,
      Citations             = Citations,
      Link                  = Link,
      Image                 = Image,
      Code                  = Code,
      AutoLinkUrl           = AutoLinkUrl,
      AutoLinkEmail         = AutoLinkEmail,
      InlineHtml            = InlineHtml,
      HtmlEntity            = HtmlEntity,
      EscapedChar           = EscapedChar,
      Smart                 = Smart,
      Symbol                = Symbol,
    }

  if not options.definitionLists then
    syntax.DefinitionList = fail
  end

  if not options.fencedCode then
    syntax.FencedCode = fail
  end

  if not options.citations then
    syntax.Citations = fail
  end

  if not options.footnotes then
    syntax.NoteRef = fail
  end

  if not options.smartEllipses then
    syntax.Smart = fail
  end

  local blocks_toplevel_t = util.table_copy(syntax)
  blocks_toplevel_t.Paragraph = ToplevelParagraph
  blocks_toplevel = Ct(blocks_toplevel_t)

  blocks = Ct(syntax)

  local inlines_t = util.table_copy(syntax)
  inlines_t[1] = "Inlines"
  inlines_t.Inlines = Inline^0 * (spacing^0 * eof / "")
  inlines = Ct(inlines_t)

  local inlines_no_link_t = util.table_copy(inlines_t)
  inlines_no_link_t.Link = fail
  inlines_no_link = Ct(inlines_no_link_t)

  local inlines_nbsp_t = util.table_copy(inlines_t)
  inlines_nbsp_t.Endline = NonbreakingEndline
  inlines_nbsp_t.Space = NonbreakingSpace
  inlines_nbsp = Ct(inlines_nbsp_t)
  function self.convert(input)
    references = {}
    local opt_string = {}
    for k,_ in pairs(defaultOptions) do
      local v = options[k]
      if k ~= "cacheDir" then
        opt_string[#opt_string+1] = k .. "=" .. tostring(v)
      end
    end
    table.sort(opt_string)
    local salt = table.concat(opt_string, ",") .. "," .. metadata.version
    local name = util.cache(options.cacheDir, input, salt, function(input)
        return util.rope_to_string(parse_blocks_toplevel(input)) .. writer.eof
      end, ".md" .. writer.suffix)
    return writer.pack(name)
  end
  return self
end
function M.new(options)
  local writer = M.writer.new(options)
  local reader = M.reader.new(writer, options)
  return reader.convert
end

return M
