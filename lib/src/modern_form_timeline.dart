part of '../modern_form_stepper.dart';


/// Timeline compacta para exibir [ModernFormStep]s de forma sempre visível,
/// com suporte a "Ver mais" e expansão individual de descrição por toque.
class ModernFormTimeline extends StatefulWidget {
  final List<ModernFormStep> steps;

  /// Quantos steps mostrar por padrão (os mais recentes).
  ///
  /// Quando não informado, a timeline não oculta etapas e exibe todos os
  /// itens sem botão de expansão/recolhimento.
  final int? defaultVisible;

  /// Cor usada nos steps já concluídos.
  /// Se não fornecida, usa [ColorScheme.secondary] do tema.
  final Color? completedColor;

  /// Índice da etapa atual para realce visual no timeline.
  ///
  /// Quando informado, tem prioridade sobre [ModernFormStep.isActive].
  final int? currentStepIndex;

  const ModernFormTimeline({
    required this.steps,
    this.defaultVisible,
    this.completedColor,
    this.currentStepIndex,
    super.key,
  });

  @override
  State<ModernFormTimeline> createState() => _ModernFormTimelineState();
}

class _ModernFormTimelineState extends State<ModernFormTimeline> {
  bool _expanded = false;

  /// Índice dentro de widget.steps do item selecionado (-1 = nenhum).
  int _selectedIndex = -1;
  bool _hasUserSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialSelectedIndex();
  }

  int _initialSelectedIndex() {
    if (widget.steps.isEmpty) return -1;
    final int lastIndex = widget.steps.length - 1;
    return _isEffectivelyEmptyContent(widget.steps[lastIndex].content)
        ? -1
        : lastIndex;
  }

  @override
  void didUpdateWidget(ModernFormTimeline old) {
    super.didUpdateWidget(old);
    if (!identical(old.steps, widget.steps)) {
      _selectedIndex = _initialSelectedIndex();
      _hasUserSelection = false;
      // Recolhe automaticamente se a lista encolher abaixo do limite visível,
      // evitando que _expanded fique true sem botão de recolher visível.
      if (!_canHideSteps) {
        _expanded = false;
      }
    }
  }

  bool get _canHideSteps =>
      widget.defaultVisible != null && widget.steps.length > widget.defaultVisible!;

  bool get _hasHidden => !_expanded && _canHideSteps;

  int get _hiddenCount => widget.steps.length - widget.defaultVisible!;

  List<ModernFormStep> get _visibleSteps => _hasHidden
      ? widget.steps.sublist(widget.steps.length - widget.defaultVisible!)
      : widget.steps;

  int _globalIndex(int visibleIndex) => _hasHidden
      ? widget.steps.length - widget.defaultVisible! + visibleIndex
      : visibleIndex;

  int get _resolvedCurrentStepIndex {
    final external = widget.currentStepIndex;
    if (external != null && external >= 0 && external < widget.steps.length) {
      return external;
    }

    // Fallback para compatibilidade: usa a primeira etapa marcada como ativa.
    for (var i = 0; i < widget.steps.length; i++) {
      if (widget.steps[i].isActive) return i;
    }
    return -1;
  }

  void _onTapItem(int globalIndex) {
    setState(() {
      _selectedIndex = globalIndex;
      _hasUserSelection = true;
    });
  }

  void _collapse() {
    setState(() {
      _expanded = false;
      _selectedIndex = -1;
      _hasUserSelection = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleSteps = _visibleSteps;
    final bool showExpandControls = _canHideSteps;
    final int processCurrentStepIndex = _resolvedCurrentStepIndex;
    final int highlightedStepIndex =
        _hasUserSelection && _selectedIndex >= 0
            ? _selectedIndex
            : processCurrentStepIndex;
    final int expandedStepIndex =
        _selectedIndex >= 0 ? _selectedIndex : processCurrentStepIndex;

    return Padding(
      padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasHidden)
            _TimelineVerMaisButton(
              hiddenCount: _hiddenCount,
              onTap: () => setState(() => _expanded = true),
            ),
          // Botão "Recolher" no topo: conveniência para listas longas expandidas.
          if (_expanded && showExpandControls)
            _TimelineRecolherButton(onTap: _collapse),
          ...List.generate(visibleSteps.length, (i) {
            final gi = _globalIndex(i);
            final bool isExpandedItem = gi == expandedStepIndex;
            return _TimelineItem(
              step: visibleSteps[i],
              isFirst: i == 0 && _hasHidden,
              isLast: i == visibleSteps.length - 1,
              isCurrent: gi == highlightedStepIndex,
              isSelected: isExpandedItem,
              completedColor: widget.completedColor,
              onTap: () => _onTapItem(gi),
            );
          }),
          // Botão "Recolher" no rodapé: espelha o do topo para evitar scroll.
          if (_expanded && showExpandControls)
            _TimelineRecolherButton(onTap: _collapse),
        ],
      ),
    );
  }
}

// ── Botões "Ver mais" / "Recolher" ────────────────────────────────────────────

class _TimelineVerMaisButton extends StatelessWidget {
  final int hiddenCount;
  final VoidCallback onTap;

  const _TimelineVerMaisButton({required this.hiddenCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.expand_more, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                "Ver mais $hiddenCount etapa${hiddenCount > 1 ? 's' : ''} "
                "anterior${hiddenCount > 1 ? 'es' : ''}",
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRecolherButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TimelineRecolherButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, left: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.expand_less, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                "Recolher",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item da timeline ──────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  final ModernFormStep step;
  final bool isLast;
  final bool isFirst;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? completedColor;

  const _TimelineItem({
    required this.step,
    required this.isLast,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.completedColor,
  });

  static const double _dotSizeNormal = 9.0;
  static const double _dotSizeCurrent = 13.0;
  static const double _leftColumnWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotSize = isCurrent ? _dotSizeCurrent : _dotSizeNormal;
    final resolved = completedColor ?? theme.colorScheme.secondary;
    final dotColor = isCurrent ? theme.colorScheme.primary : resolved;

    final double bottomSpacing = isLast ? 4.0 : 8.0;
    final titleColor =
        isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Coluna da linha/ponto ──────────────────────────
          SizedBox(
            width: _leftColumnWidth,
            child: Column(
              children: [
                if (isFirst)
                  Container(
                    width: 2,
                    height: 10,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    top: isFirst ? 0 : 3.0 + (_dotSizeCurrent - dotSize) / 2,
                  ),
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.28),
                                blurRadius: 7,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check,
                        size: isCurrent ? 8 : 6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Conteúdo ───────────────────────────────────────
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome — sempre clicável para permitir seleção da etapa.
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onTap,
                      behavior: HitTestBehavior.translucent,
                      child: DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          height: 1.3,
                        ),
                        child: step.title,
                      ),
                    ),
                  ),
                  // Data + responsável
                  if (step.subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle.merge(
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                      child: step.subtitle!,
                    ),
                  ],
                  // Só renderiza descrição se houver conteúdo de fato.
                  if (!_isEffectivelyEmptyContent(step.content))
                    _TimelineStepDescription(
                      content: step.content!,
                      isExpanded: isSelected,
                      accentColor: isCurrent
                          ? theme.colorScheme.primary
                          : resolved,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isEffectivelyEmptyContent(Widget? content) {
  if (content == null) return true;

  if (content is SizedBox) {
    return content.child == null;
  }

  if (content is Text) {
    final String plainTextFromData = (content.data ?? '').trim();
    final String plainTextFromSpan = content.textSpan
            ?.toPlainText(
              includeSemanticsLabels: false,
              includePlaceholders: false,
            )
            .trim() ??
        '';
    return plainTextFromData.isEmpty && plainTextFromSpan.isEmpty;
  }

  if (content is Row) {
    return content.children.isEmpty;
  }

  if (content is Column) {
    return content.children.isEmpty;
  }

  if (content is Flex) {
    return content.children.isEmpty;
  }

  return false;
}

// ── Descrição expansível ──────────────────────────────────────────────────────

class _TimelineStepDescription extends StatelessWidget {
  final Widget content;
  final bool isExpanded;
  final Color accentColor;

  const _TimelineStepDescription({
    required this.content,
    required this.isExpanded,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: isExpanded
          // ── Versão expandida: bloco com container destacado ──
          ? Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border(
                    left: BorderSide(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2.5,
                    ),
                  ),
                ),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                    height: 1.4,
                  ),
                  child: content,
                ),
              ),
            )
          // ── Versão compacta: 1 linha truncada, sem container ──
          : Padding(
              padding: const EdgeInsets.only(top: 3.0),
              child: SizedBox(
                height: 15,
                child: ClipRect(
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      height: 1.3,
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
    );
  }
}
