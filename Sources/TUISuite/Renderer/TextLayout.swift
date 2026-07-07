public enum LineBreakMode {
    case wordWrap, charWrap, none
}
public enum TruncationMode {
    case head,middle,tail
}

public struct TextLayout {
    
    private static func wrapByCharacter(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        var currentLine = ""
        for char in text {
            currentLine.append(char)
            if currentLine.count == width {
                lines.append(currentLine)
                currentLine = ""
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        return lines
    }
    
    private static func wrapByWord(_ text: String, width: Int) -> [String] {
        var lines: [String] = []
        let words = text.split(separator: " ",omittingEmptySubsequences: false)
        var currentLine = ""
        for word in words {
            let strWord = String(word)
            if currentLine.isEmpty {
                if strWord.count > width {
                    let split = wrapByCharacter(strWord,width:width)
                    lines.append(contentsOf: split.dropLast())
                    currentLine = split.last ?? ""
                } else {
                    currentLine.append(strWord)
                }
            } else {
                if currentLine.count + 1 + strWord.count <= width {
                    currentLine.append(" " + strWord)
                } else {
                    lines.append(currentLine)
                    if strWord.count > width {
                        let split = wrapByCharacter(strWord,width:width)
                        lines.append(contentsOf: split.dropLast())
                        currentLine = split.last ?? ""
                    } else {
                        currentLine = strWord
                    }
                }
            }
        }
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        return lines
    }
    
    public static func wrap(_ text: String, width: Int,mode: LineBreakMode = .wordWrap) -> [String] {
        guard width > 0 else { return [] }
        
        if(mode == .none) {
            return [text]
        }
        
        var lines: [String] = []
        let rawLines = text.components(separatedBy: .newlines)
        for line in rawLines {
            if line.isEmpty {
                lines.append("")
                continue
            }
            if mode == .wordWrap {
                lines.append(contentsOf: wrapByWord(line, width: width))
            } else if mode == .charWrap {
                lines.append(contentsOf: wrapByCharacter(line, width: width))
            }
        }
        return lines
    }
    
    public static func truncate(_ text:String,width:Int,mode: TruncationMode = .tail,ellipsis:String="...") -> String {
        guard text.count > width else { return text }
        guard width > ellipsis.count else { return String(ellipsis.prefix(width)) }
        let available = width - ellipsis.count
        switch mode {
        case .head:
            return ellipsis + String(text.suffix(available))
        case .middle:
            let headLen = (available+1)/2
            let tailLen = available - headLen
            return String(text.prefix(headLen))+ellipsis+String(text.suffix(tailLen))
        case .tail:
            return String(text.prefix(available)) + ellipsis
        }
    }
}
