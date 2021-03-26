library sticky_footer_scrollview;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

///sticky footer scroll view
class StickyFooterScrollView extends StatefulWidget {
  ///scroll body children count
  final int itemCount;

  ///scroll body children
  final IndexedWidgetBuilder itemBuilder;

  ///footer widget that stick to the bottom
  final Widget footer;

  ///scroll control of this scrollview
  final ScrollController? scrollController;

  StickyFooterScrollView({
    Key? key,
    required this.footer,
    required this.itemBuilder,
    required this.itemCount,
    this.scrollController,
  })  : assert(itemCount >= 0, 'itemCount must >=0'),
        super(key: key);

  @override
  _StickyFooterScrollViewState createState() => _StickyFooterScrollViewState();
}

class _StickyFooterScrollViewState extends State<StickyFooterScrollView> {
  ///scroll body width
  double? _width;

  ///scroll body height
  double? _height;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: _height ?? double.maxFinite),
          child: CustomMultiChildLayout(
            delegate: StickyHeaderFooterScrollViewDelegate(
              constraint.maxHeight,
              constraint.maxWidth,
              (width, height) {
                if (width != _width || height != _height) {
                  _width = width;
                  _height = height;
                  //setState when this frame finished
                  SchedulerBinding.instance?.addPostFrameCallback((_) {
                    setState(() {});
                  });
                }
              },
            ),
            children: [
              LayoutId(
                id: StickyScrollView.Body,
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: widget.itemBuilder,
                  itemCount: widget.itemCount,
                ),
              ),
              LayoutId(
                id: StickyScrollView.Footer,
                child: widget.footer,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class StickyHeaderFooterScrollViewDelegate extends MultiChildLayoutDelegate {
  ///widget available height
  final double height;

  ///widget avaiable width
  final double width;

  ///size update callback
  final Function updateSize;

  StickyHeaderFooterScrollViewDelegate(
      this.height, this.width, this.updateSize);

  @override
  void performLayout(Size size) {
    ///default height setting
    Size leadingSize = Size.zero;

    if (hasChild(StickyScrollView.Body)) {
      leadingSize = layoutChild(
        StickyScrollView.Body,
        BoxConstraints(
          maxWidth: this.width,
        ),
      );

      positionChild(
        StickyScrollView.Body,
        Offset(0, 0),
      );
    }

    if (hasChild(StickyScrollView.Footer)) {
      Size footerSize = layoutChild(
        StickyScrollView.Footer,
        BoxConstraints(
          maxWidth: this.width,
        ),
      );
      double remainingHeight =
          this.height - leadingSize.height - footerSize.height;

      if (remainingHeight > 0) {
        //sticky footer
        positionChild(
          StickyScrollView.Footer,
          Offset(0, this.height - footerSize.height),
        );
        this.updateSize(width, height);
      } else {
        //append to list
        positionChild(
          StickyScrollView.Footer,
          Offset(0, leadingSize.height),
        );
        this.updateSize(width, leadingSize.height + footerSize.height);
      }
    }
  }

  @override
  bool shouldRelayout(covariant MultiChildLayoutDelegate oldDelegate) {
    return oldDelegate != this;
  }
}

enum StickyScrollView { Body, Footer }
