/*
 * FILE:	StarRatingView.swift
 * DESCRIPTION:	StarRatingViewSwiftUI: View to Provide Star Rating Features
 * DATE:	Sat, May 28 2022
 * UPDATED:	Fri, Jun 24 2022
 * AUTHOR:	Kouichi ABE (WALL) / 阿部康一
 * E-MAIL:	kouichi@MagickWorX.COM
 * URL:		https://www.MagickWorX.COM/
 * COPYRIGHT:	(c) 2022 阿部康一／Kouichi ABE (WALL)
 * LICENSE:	The 2-Clause BSD License (See LICENSE.txt)
 */

import SwiftUI

/*
 * Reference:
 * Star rating view in SwiftUI | Swift UI recipes
 * https://swiftuirecipes.com/blog/star-rating-view-in-swiftui
 */
public struct StarRatingView: View
{
  private let theRating: Float
  private let color: Color // The color of the stars
  private let maxRating: Float // Defines upper limit of the rating
  private var needsComputing: Bool = false

  public init(rating: Float, color: Color = .orange, maxRating: Float = 5) {
    self.theRating = rating
    self.color = color
    self.maxRating = maxRating
    self._rating = .constant(rating) // XXX: Dummy
  }

  @Binding private var rating: Float

  public init(rating: Binding<Float>, color: Color = .orange, maxRating: Float = 5) {
    self.theRating = rating.wrappedValue
    self.color = color
    self.maxRating = maxRating
    self._rating = rating
    self.needsComputing = true
  }

  public var body: some View {
    GeometryReader { geometry in
      let l: CGFloat = floor(geometry.size.height)
      let s: CGFloat = floor(l * 0.2) // space between stars
      let w: CGFloat = (l + s) * CGFloat(maxRating)
      HStack(spacing: s) {
        ForEach(0..<fullCount, id: \.self) { _ in
          self.fullStar.frame(width: l, height: l)
        }
        ForEach(0..<halfFullCount, id: \.self) { _ in
          self.halfFullStar.frame(width: l, height: l)
        }
        ForEach(0..<emptyCount, id: \.self) { _ in
          self.emptyStar.frame(width: l, height: l)
        }
      }
      .gesture(needsComputing ? tap(on: w) : nil)
    }
  }
}

extension StarRatingView
{
  private var fullCount: Int {
    if needsComputing {
      return Int(self.rating)
    }
    return Int(theRating)
  }

  private var emptyCount: Int {
    if needsComputing {
      return Int(maxRating - self.rating)
    }
    return Int(maxRating - theRating)
  }

  private var halfFullCount: Int {
    return (Float(fullCount + emptyCount) < maxRating) ? 1 : 0
  }
}

extension StarRatingView
{
  private var fullStar: some View {
    Image(systemName: "star.fill")
      .resizable()
      .foregroundColor(color)
  }

  private var halfFullStar: some View {
    Image(systemName: "star.lefthalf.fill")
      .resizable()
      .foregroundColor(color)
  }

  private var emptyStar: some View {
    Image(systemName: "star")
      .resizable()
      .foregroundColor(color)
  }
}

extension StarRatingView
{
  private enum SwipeDirection
  {
    case unknown
    case right
    case left
    case up
    case down
  }

  private func swipeDirection(_ translation: CGSize) -> SwipeDirection {
    /*
     * swipe - How to detect Swiping UP, DOWN, LEFT and RIGHT with SwiftUI on a View - Stack Overflow
     * https://stackoverflow.com/questions/60885532/how-to-detect-swiping-up-down-left-and-right-with-swiftui-on-a-view
     */
    switch(translation.width, translation.height) {
      case (0..., -30...30):   return .right
      case (...0, -30...30):   return .left
      case (-100...100, ...0): return .up
      case (-100...100, 0...): return .down
      default:                 return .unknown
    }
  }

  private func swipe(on length: CGFloat) -> some Gesture {
    /*
     * XXX:
     * minimumDistance が 0.0 なのは TapGesture のタップにも反応させるため
     */
    DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
      .onChanged { value in
        self.computeRating(with: value, on: length)
      }
      .onEnded { value in
        self.computeRating(with: value, on: length)
      }
  }

  private func computeRating(with value: DragGesture.Value, on length: CGFloat) {
    guard self.needsComputing else { return }

    let x = max(0.0, min(floor(value.location.x), length))
    let r = Float(round((x / length) * 100 * CGFloat(maxRating / 10)) / 10)
    switch swipeDirection(value.translation) {
      case .right, .left:
        self.rating = {
          // XXX: 0.5 単位にする処理
          let t = round(r)
          switch t {
            case 0.0: if r == 0.0 { return 0.0 }
            case maxRating: return maxRating
            default: break
          }
          return t > r ? t : t + 0.5
        }()
      default: break
    }
  }
}

extension StarRatingView
{
  private func tap(on length: CGFloat) -> some Gesture {
    TapGesture(count: 1)
      .onEnded { _ in
        // XXX: TapGesture は値を返さないようだ…(T_T)
      }
      .simultaneously(with: swipe(on: length))
  }
}

struct StarRatingView_Previews: PreviewProvider
{
  @State static var rating: Float = 1.5

  static var previews: some View {
    Group {
      StarRatingView(rating: 4)
      StarRatingView(rating: 5.5, color: .pink, maxRating: 7)
      // Changable with Swipe
      StarRatingView(rating: $rating)
        .onChange(of: rating) { newValue in
          print(newValue)
        }
    }
    .frame(width: 300, height: 30)
    .previewLayout(.fixed(width: 300, height: 40))
  }
}
