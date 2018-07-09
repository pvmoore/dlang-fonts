module fonts.sdf.sdf_paragraph;

import fonts.all;

interface ParagraphWriteCallback {
    void write(int x, int y, string text);
}

private alias Callback = void delegate(int x,int y,string text);

final class SDFParagraph {
	Rect rect;
	int lineSpacing;
	int wordSpacing;
	Rect prevRect;
	Callback write;
	SDFFont font;
	float fontSize;
	// TODO - cache frequently used strings as this object is likely to be reused
public:
	this(Rect r, Callback cb, SDFFont font, float fontSize, int lineSpacing=4, int wordSpacing=4) {
		this.rect        = r;
		this.write       = cb;
		this.font        = font;
		this.fontSize    = fontSize;
		this.lineSpacing = lineSpacing;
		this.wordSpacing = wordSpacing;
		reset();
	}
	auto newLine() {
		// TODO - this won't work if prevRect size is 0
		prevRect.x = rect.x;
		prevRect.y += prevRect.height + lineSpacing;
		prevRect.width = 0;
		return this;
	}
	auto left(string s) {
		foreach(w; s.split()) {
			writeWord(w, font.getDimension(w,fontSize), wordSpacing);
		}
		return this;
	}
	auto centred(string s) {
		auto dim = font.getDimension(s,fontSize);
		float rightEdge = rect.x + rect.width;
		float leftEdge  = prevRect.x + prevRect.width;
		float remainder = (rightEdge-leftEdge)-dim.width;
		if(remainder<0) {
			// we don't have enough room on the line
			log("not enough room");
			return left(s);
		}
		prevRect.width += remainder/2;
		return left(s);
	}
	auto justified(string s) {
		float rightEdge = rect.x + rect.width;
		float leftEdge  = prevRect.x + prevRect.width;
		Tuple!(string,Dimension)[] tokens;

		foreach(w; s.split()) {
			tokens ~= Tuple!(string,Dimension)(w,font.getDimension(w,fontSize));
		}

		int countWordsUntilEOL() {
			float remainingWidth = rightEdge - leftEdge;
			int count;
			foreach(t; tokens) {
				remainingWidth -= (t[1].width + wordSpacing);
				if(remainingWidth < 0) break;
				count++;
			}
			return count;
		}

		while(tokens.length > 0) {
			leftEdge  = prevRect.x + prevRect.width;
			int count = countWordsUntilEOL();

			//log("para: count=%s token[0]=%s", count, tokens[0][0]);

			if(count==0 && tokens[0][1].width > rect.width) {
				// this word is too big for the rect width. just print it
				count = 1;
			}

			if(count==0) {
				// no words fit on this line. go to the next line
				newLine();
			} else if(count==1) {
				// 1 word fits on this line
				writeWord(tokens[0][0], tokens[0][1], wordSpacing);
				tokens = tokens[1..$];
			} else {
				// justify
				float combinedTextWidth = tokens[0..count].map!(it=>it[1].width).sum();
				float wordSpacing = ((rightEdge-leftEdge)-combinedTextWidth) / (count-1);
				foreach(t; tokens[0..count]) {
					writeWord(t[0], t[1], wordSpacing);
				}
				tokens = tokens[count..$];
			}
		}
		return this;
	}
	void reset() { prevRect = Rect(rect.xy, 0,0); }//rect.origin.toRect(Dimension(0,0)); }
private:
	auto writeWord(string s, Dimension textDim, float wordSpacing) {
		float x = prevRect.x + prevRect.width;
		float y = prevRect.y;
		if(x + textDim.width > rect.x + rect.width) {
			// wrap
			x = rect.x;
			y += prevRect.height + lineSpacing;
		}
		//prevRect = Point(x, y).toRect(Dimension(textDim.width + wordSpacing, textDim.height));
        prevRect = Rect(x,y, textDim.width + wordSpacing, textDim.height);

        write(cast(int)x, cast(int)y, s);
		return this;
	}
}



