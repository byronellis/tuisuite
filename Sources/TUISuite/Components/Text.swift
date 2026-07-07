private class Cache<T>  {
    var value : T
    init(_ value: T) { self.value = value }
}
public struct Text : Component {
    
    public var text: String
    public var lineLimit: Int?
    public var truncationMode: TruncationMode
    public var lineBreakMode: LineBreakMode
    
    private var cache: Cache<(lines:[String],lastText: String, lastProposal:ProposedSize?)>
    
    public init(_ text: String,lineLimit:Int? = nil,truncate: TruncationMode = .tail,wrap: LineBreakMode = .wordWrap) {
        self.text = text
        self.lineLimit = lineLimit
        self.truncationMode = truncate
        self.lineBreakMode = wrap
        self.cache = Cache((lines: [], lastText: text, lastProposal: nil))
    }
    
    public func sizeThatFits(proposal: ProposedSize, context: Context) -> Size {
        // 1. FAST PATH Bypasses calculations if text, widths, AND height constraints match
        if cache.value.lastText == text,
           let lastProposal = cache.value.lastProposal,
           lastProposal.width == proposal.width,
           lastProposal.height == proposal.height {
            
            let cachedLines = cache.value.lines
            let computedWidth = cachedLines.map { $0.count }.max() ?? 0
            let computedHeight = cachedLines.count
            
            return Size(
                minWidth: min(1, computedWidth), idealWidth: computedWidth, maxWidth: proposal.width,
                minHeight: computedHeight, idealHeight: computedHeight, maxHeight: computedHeight
            )
        }
        
        // 2. Determine target width constraints
        let targetWidth = proposal.width ?? Int.max
        let maxLinesAllowed = min(lineLimit ?? Int.max, proposal.height ?? Int.max)
        
        var calculatedLines = [String]()
        
        // 3. Handle Single-Line Truncation Modes
        if lineBreakMode == .none || maxLinesAllowed == 1 {
            let singleLine = text.replacingOccurrences(of: "\n", with: " ")
            let truncated = TextLayout.truncate(singleLine, width: targetWidth, mode: truncationMode)
            calculatedLines = [truncated]
        } else {
            // 4. Handle Multiline Wrapping Modes (Fixes the double wrapping bug!)
            let rawWrappedLines = TextLayout.wrap(text, width: targetWidth, mode: lineBreakMode)
            
            if rawWrappedLines.count > maxLinesAllowed {
                // Take lines up to the limit
                var truncatedLines = Array(rawWrappedLines.prefix(maxLinesAllowed))
                
                // Truncate the last visible line using your text layout engine
                if let lastLine = truncatedLines.last, !lastLine.isEmpty {
                    truncatedLines[truncatedLines.count - 1] = TextLayout.truncate(lastLine, width: targetWidth, mode: truncationMode)
                }
                calculatedLines = truncatedLines
            } else {
                calculatedLines = rawWrappedLines
            }
        }
        
        // 5. Commit calculations to persistent memory cache
        cache.value.lines = calculatedLines
        cache.value.lastText = text
        cache.value.lastProposal = proposal
        
        // 6. Return layout requirements profile
        let idealWidth = calculatedLines.map { $0.count }.max() ?? 0
        let finalHeight = calculatedLines.count
        
        
        let resolvedMaxWidth = if lineBreakMode == .none || maxLinesAllowed == 1 {
            idealWidth // Rigid single line
        } else if idealWidth < (proposal.width ?? Int.max) {
            idealWidth // Text is short; hug content width tightly
        } else {
            proposal.width // Text actually wrapped; scale to allocated box limit
        }
        
        
        return Size(
            minWidth: min(1, idealWidth),
            idealWidth: idealWidth,
            maxWidth: resolvedMaxWidth,
            minHeight: finalHeight,
            idealHeight: finalHeight,
            maxHeight: finalHeight
        )    }
    
    public func render(renderer: Renderer, bounds: Rect, context: Context) {
        // Render out the exact lines populated by the measurement pass
        for (i, line) in cache.value.lines.enumerated() {
            guard i < bounds.height else { break }
            
            // Clip line length to ensure it fits the final bounding box layout allocation
            let clippedLine = line.count > bounds.width ? String(line.prefix(bounds.width)) : line
            
            renderer.drawString(
                clippedLine,
                x: bounds.x,
                y: bounds.y + i,
                fg: context.fg,
                bg: context.bg,
                modifiers: context.modifier
            )
        }
    }

}
