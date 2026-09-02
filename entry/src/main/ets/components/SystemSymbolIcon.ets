@Component
export struct SystemSymbolIcon {
  symbol: Resource = $r('sys.symbol.checkmark');
  @Prop color: ResourceColor = $r('app.color.key_text');
  @Prop iconSize: number = 20;

  build() {
    SymbolGlyph(this.symbol)
      .fontSize(this.iconSize)
      .fontColor([this.color])
  }
}
