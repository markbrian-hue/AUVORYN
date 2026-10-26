/// Offline-only, user-selected presence in the listening apartment.
enum CompanionStyle { boy, girl, emoBoy, emoGirl }
enum CompanionPose { sofa, standing, window }
enum CompanionHair { cropped, waves, long, fringe }
enum CompanionSkin { light, warm, deep }
enum CompanionOutfit { oatmeal, sage, charcoal, plum }

extension CompanionStyleLabel on CompanionStyle {
  String get label => switch (this) {
    CompanionStyle.boy => 'Boy',
    CompanionStyle.girl => 'Girl',
    CompanionStyle.emoBoy => 'Emo boy',
    CompanionStyle.emoGirl => 'Emo girl',
  };
}

extension CompanionPoseLabel on CompanionPose {
  String get label => switch (this) {
    CompanionPose.sofa => 'Relaxing on the sofa',
    CompanionPose.standing => 'Standing by the rug',
    CompanionPose.window => 'By the window',
  };
}

extension CompanionHairLabel on CompanionHair {
  String get label => switch (this) {
    CompanionHair.cropped => 'Short',
    CompanionHair.waves => 'Soft waves',
    CompanionHair.long => 'Long',
    CompanionHair.fringe => 'Side fringe',
  };
}

extension CompanionSkinLabel on CompanionSkin {
  String get label => switch (this) {
    CompanionSkin.light => 'Light',
    CompanionSkin.warm => 'Warm',
    CompanionSkin.deep => 'Deep',
  };
}

extension CompanionOutfitLabel on CompanionOutfit {
  String get label => switch (this) {
    CompanionOutfit.oatmeal => 'Oatmeal',
    CompanionOutfit.sage => 'Sage',
    CompanionOutfit.charcoal => 'Charcoal',
    CompanionOutfit.plum => 'Plum',
  };
}

class RoomCompanion {
  const RoomCompanion({
    this.visible = true,
    this.style = CompanionStyle.boy,
    this.pose = CompanionPose.sofa,
    this.hair = CompanionHair.cropped,
    this.skin = CompanionSkin.warm,
    this.outfit = CompanionOutfit.oatmeal,
  });

  final bool visible;
  final CompanionStyle style;
  final CompanionPose pose;
  final CompanionHair hair;
  final CompanionSkin skin;
  final CompanionOutfit outfit;

  static RoomCompanion forStyle(
    CompanionStyle style, {
    CompanionSkin skin = CompanionSkin.warm,
    CompanionPose pose = CompanionPose.sofa,
  }) => RoomCompanion(
    style: style,
    skin: skin,
    pose: pose,
    hair: switch (style) {
      CompanionStyle.boy => CompanionHair.cropped,
      CompanionStyle.girl => CompanionHair.long,
      CompanionStyle.emoBoy || CompanionStyle.emoGirl => CompanionHair.fringe,
    },
    outfit: switch (style) {
      CompanionStyle.boy => CompanionOutfit.oatmeal,
      CompanionStyle.girl => CompanionOutfit.sage,
      CompanionStyle.emoBoy => CompanionOutfit.charcoal,
      CompanionStyle.emoGirl => CompanionOutfit.plum,
    },
  );

  RoomCompanion copyWith({
    bool? visible,
    CompanionStyle? style,
    CompanionPose? pose,
    CompanionHair? hair,
    CompanionSkin? skin,
    CompanionOutfit? outfit,
  }) => RoomCompanion(
    visible: visible ?? this.visible,
    style: style ?? this.style,
    pose: pose ?? this.pose,
    hair: hair ?? this.hair,
    skin: skin ?? this.skin,
    outfit: outfit ?? this.outfit,
  );

  Map<String, Object?> toJson() => {
    'schema': 1,
    'visible': visible,
    'style': style.name,
    'pose': pose.name,
    'hair': hair.name,
    'skin': skin.name,
    'outfit': outfit.name,
  };

  factory RoomCompanion.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 || json['visible'] is! bool) {
      throw const FormatException('Unsupported companion settings.');
    }
    return RoomCompanion(
      visible: json['visible'] as bool,
      style: _readEnum(CompanionStyle.values, json['style']),
      pose: _readEnum(CompanionPose.values, json['pose']),
      hair: _readEnum(CompanionHair.values, json['hair']),
      skin: _readEnum(CompanionSkin.values, json['skin']),
      outfit: _readEnum(CompanionOutfit.values, json['outfit']),
    );
  }

  static T _readEnum<T extends Enum>(List<T> options, Object? raw) {
    for (final option in options) {
      if (option.name == raw) return option;
    }
    throw const FormatException('Unknown companion customization value.');
  }
}
