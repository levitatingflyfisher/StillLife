// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $PropertiesTable extends Properties
    with TableInfo<$PropertiesTable, Property> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PropertiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Home'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    type,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'properties';
  @override
  VerificationContext validateIntegrity(
    Insertable<Property> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Property map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Property(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PropertiesTable createAlias(String alias) {
    return $PropertiesTable(attachedDatabase, alias);
  }
}

class Property extends DataClass implements Insertable<Property> {
  final String id;
  final String name;
  final String? address;
  final String type;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Property({
    required this.id,
    required this.name,
    this.address,
    required this.type,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['type'] = Variable<String>(type);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PropertiesCompanion toCompanion(bool nullToAbsent) {
    return PropertiesCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      type: Value(type),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Property.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Property(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      type: serializer.fromJson<String>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'type': serializer.toJson<String>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Property copyWith({
    String? id,
    String? name,
    Value<String?> address = const Value.absent(),
    String? type,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Property(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    type: type ?? this.type,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Property copyWithCompanion(PropertiesCompanion data) {
    return Property(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Property(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    type,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Property &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class PropertiesCompanion extends UpdateCompanion<Property> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<String> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PropertiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PropertiesCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.type = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Property> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PropertiesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? address,
    Value<String>? type,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PropertiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PropertiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _propertyIdMeta = const VerificationMeta(
    'propertyId',
  );
  @override
  late final GeneratedColumn<String> propertyId = GeneratedColumn<String>(
    'property_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES properties (id)',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _floorMeta = const VerificationMeta('floor');
  @override
  late final GeneratedColumn<String> floor = GeneratedColumn<String>(
    'floor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    propertyId,
    parentId,
    name,
    floor,
    sortOrder,
    photoPath,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Room> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('property_id')) {
      context.handle(
        _propertyIdMeta,
        propertyId.isAcceptableOrUnknown(data['property_id']!, _propertyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_propertyIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('floor')) {
      context.handle(
        _floorMeta,
        floor.isAcceptableOrUnknown(data['floor']!, _floorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      propertyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}property_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      floor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}floor'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final String id;
  final String propertyId;
  final String? parentId;
  final String name;
  final String? floor;
  final int sortOrder;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Room({
    required this.id,
    required this.propertyId,
    this.parentId,
    required this.name,
    this.floor,
    required this.sortOrder,
    this.photoPath,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['property_id'] = Variable<String>(propertyId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || floor != null) {
      map['floor'] = Variable<String>(floor);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      propertyId: Value(propertyId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      floor: floor == null && nullToAbsent
          ? const Value.absent()
          : Value(floor),
      sortOrder: Value(sortOrder),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Room.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<String>(json['id']),
      propertyId: serializer.fromJson<String>(json['propertyId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      floor: serializer.fromJson<String?>(json['floor']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'propertyId': serializer.toJson<String>(propertyId),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'floor': serializer.toJson<String?>(floor),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'photoPath': serializer.toJson<String?>(photoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Room copyWith({
    String? id,
    String? propertyId,
    Value<String?> parentId = const Value.absent(),
    String? name,
    Value<String?> floor = const Value.absent(),
    int? sortOrder,
    Value<String?> photoPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Room(
    id: id ?? this.id,
    propertyId: propertyId ?? this.propertyId,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    floor: floor.present ? floor.value : this.floor,
    sortOrder: sortOrder ?? this.sortOrder,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      propertyId: data.propertyId.present
          ? data.propertyId.value
          : this.propertyId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      floor: data.floor.present ? data.floor.value : this.floor,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('propertyId: $propertyId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('floor: $floor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    propertyId,
    parentId,
    name,
    floor,
    sortOrder,
    photoPath,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.propertyId == this.propertyId &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.floor == this.floor &&
          other.sortOrder == this.sortOrder &&
          other.photoPath == this.photoPath &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<String> id;
  final Value<String> propertyId;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String?> floor;
  final Value<int> sortOrder;
  final Value<String?> photoPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.propertyId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.floor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    required String id,
    required String propertyId,
    this.parentId = const Value.absent(),
    required String name,
    this.floor = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.photoPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       propertyId = Value(propertyId),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Room> custom({
    Expression<String>? id,
    Expression<String>? propertyId,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? floor,
    Expression<int>? sortOrder,
    Expression<String>? photoPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (propertyId != null) 'property_id': propertyId,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (floor != null) 'floor': floor,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (photoPath != null) 'photo_path': photoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith({
    Value<String>? id,
    Value<String>? propertyId,
    Value<String?>? parentId,
    Value<String>? name,
    Value<String?>? floor,
    Value<int>? sortOrder,
    Value<String?>? photoPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      floor: floor ?? this.floor,
      sortOrder: sortOrder ?? this.sortOrder,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (propertyId.present) {
      map['property_id'] = Variable<String>(propertyId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (floor.present) {
      map['floor'] = Variable<String>(floor.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('propertyId: $propertyId, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('floor: $floor, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('photoPath: $photoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorageContainersTable extends StorageContainers
    with TableInfo<$StorageContainersTable, StorageContainer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageContainersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomId,
    name,
    type,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_containers';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageContainer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageContainer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageContainer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $StorageContainersTable createAlias(String alias) {
    return $StorageContainersTable(attachedDatabase, alias);
  }
}

class StorageContainer extends DataClass
    implements Insertable<StorageContainer> {
  final String id;
  final String roomId;
  final String name;
  final String? type;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const StorageContainer({
    required this.id,
    required this.roomId,
    required this.name,
    this.type,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_id'] = Variable<String>(roomId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  StorageContainersCompanion toCompanion(bool nullToAbsent) {
    return StorageContainersCompanion(
      id: Value(id),
      roomId: Value(roomId),
      name: Value(name),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory StorageContainer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageContainer(
      id: serializer.fromJson<String>(json['id']),
      roomId: serializer.fromJson<String>(json['roomId']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String?>(json['type']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomId': serializer.toJson<String>(roomId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String?>(type),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  StorageContainer copyWith({
    String? id,
    String? roomId,
    String? name,
    Value<String?> type = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => StorageContainer(
    id: id ?? this.id,
    roomId: roomId ?? this.roomId,
    name: name ?? this.name,
    type: type.present ? type.value : this.type,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  StorageContainer copyWithCompanion(StorageContainersCompanion data) {
    return StorageContainer(
      id: data.id.present ? data.id.value : this.id,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageContainer(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roomId,
    name,
    type,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageContainer &&
          other.id == this.id &&
          other.roomId == this.roomId &&
          other.name == this.name &&
          other.type == this.type &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class StorageContainersCompanion extends UpdateCompanion<StorageContainer> {
  final Value<String> id;
  final Value<String> roomId;
  final Value<String> name;
  final Value<String?> type;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const StorageContainersCompanion({
    this.id = const Value.absent(),
    this.roomId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageContainersCompanion.insert({
    required String id,
    required String roomId,
    required String name,
    this.type = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomId = Value(roomId),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<StorageContainer> custom({
    Expression<String>? id,
    Expression<String>? roomId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomId != null) 'room_id': roomId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageContainersCompanion copyWith({
    Value<String>? id,
    Value<String>? roomId,
    Value<String>? name,
    Value<String?>? type,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return StorageContainersCompanion(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageContainersCompanion(')
          ..write('id: $id, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconCodePointMeta = const VerificationMeta(
    'iconCodePoint',
  );
  @override
  late final GeneratedColumn<int> iconCodePoint = GeneratedColumn<int>(
    'icon_code_point',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    iconCodePoint,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('icon_code_point')) {
      context.handle(
        _iconCodePointMeta,
        iconCodePoint.isAcceptableOrUnknown(
          data['icon_code_point']!,
          _iconCodePointMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      iconCodePoint: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code_point'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String? parentId;
  final int? iconCodePoint;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.iconCodePoint,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || iconCodePoint != null) {
      map['icon_code_point'] = Variable<int>(iconCodePoint);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      iconCodePoint: iconCodePoint == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCodePoint),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      iconCodePoint: serializer.fromJson<int?>(json['iconCodePoint']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'iconCodePoint': serializer.toJson<int?>(iconCodePoint),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<int?> iconCodePoint = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    iconCodePoint: iconCodePoint.present
        ? iconCodePoint.value
        : this.iconCodePoint,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      iconCodePoint: data.iconCodePoint.present
          ? data.iconCodePoint.value
          : this.iconCodePoint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    parentId,
    iconCodePoint,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.iconCodePoint == this.iconCodePoint &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<int?> iconCodePoint;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    this.parentId = const Value.absent(),
    this.iconCodePoint = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<int>? iconCodePoint,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<int?>? iconCodePoint,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (iconCodePoint.present) {
      map['icon_code_point'] = Variable<int>(iconCodePoint.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('iconCodePoint: $iconCodePoint, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6750A4'),
  );
  static const VerificationMeta _avatarEmojiMeta = const VerificationMeta(
    'avatarEmoji',
  );
  @override
  late final GeneratedColumn<String> avatarEmoji = GeneratedColumn<String>(
    'avatar_emoji',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('👤'),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    colorHex,
    avatarEmoji,
    isDefault,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('avatar_emoji')) {
      context.handle(
        _avatarEmojiMeta,
        avatarEmoji.isAcceptableOrUnknown(
          data['avatar_emoji']!,
          _avatarEmojiMeta,
        ),
      );
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      avatarEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_emoji'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final String id;
  final String name;
  final String colorHex;
  final String avatarEmoji;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Profile({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.avatarEmoji,
    required this.isDefault,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_hex'] = Variable<String>(colorHex);
    map['avatar_emoji'] = Variable<String>(avatarEmoji);
    map['is_default'] = Variable<bool>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      colorHex: Value(colorHex),
      avatarEmoji: Value(avatarEmoji),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      avatarEmoji: serializer.fromJson<String>(json['avatarEmoji']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorHex': serializer.toJson<String>(colorHex),
      'avatarEmoji': serializer.toJson<String>(avatarEmoji),
      'isDefault': serializer.toJson<bool>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Profile copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? avatarEmoji,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      avatarEmoji: data.avatarEmoji.present
          ? data.avatarEmoji.value
          : this.avatarEmoji,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    colorHex,
    avatarEmoji,
    isDefault,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorHex == this.colorHex &&
          other.avatarEmoji == this.avatarEmoji &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> colorHex;
  final Value<String> avatarEmoji;
  final Value<bool> isDefault;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesCompanion.insert({
    required String id,
    required String name,
    this.colorHex = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.isDefault = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Profile> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? colorHex,
    Expression<String>? avatarEmoji,
    Expression<bool>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorHex != null) 'color_hex': colorHex,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? colorHex,
    Value<String>? avatarEmoji,
    Value<bool>? isDefault,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (avatarEmoji.present) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorHex: $colorHex, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rooms (id)',
    ),
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentValueMeta = const VerificationMeta(
    'currentValue',
  );
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
    'current_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _replacementCostMeta = const VerificationMeta(
    'replacementCost',
  );
  @override
  late final GeneratedColumn<double> replacementCost = GeneratedColumn<double>(
    'replacement_cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _warrantyExpirationMeta =
      const VerificationMeta('warrantyExpiration');
  @override
  late final GeneratedColumn<DateTime> warrantyExpiration =
      GeneratedColumn<DateTime>(
        'warranty_expiration',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _containerIdMeta = const VerificationMeta(
    'containerId',
  );
  @override
  late final GeneratedColumn<String> containerId = GeneratedColumn<String>(
    'container_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _storeUrlMeta = const VerificationMeta(
    'storeUrl',
  );
  @override
  late final GeneratedColumn<String> storeUrl = GeneratedColumn<String>(
    'store_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isInsuredMeta = const VerificationMeta(
    'isInsured',
  );
  @override
  late final GeneratedColumn<bool> isInsured = GeneratedColumn<bool>(
    'is_insured',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_insured" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityUnitMeta = const VerificationMeta(
    'quantityUnit',
  );
  @override
  late final GeneratedColumn<String> quantityUnit = GeneratedColumn<String>(
    'quantity_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lowStockThresholdMeta = const VerificationMeta(
    'lowStockThreshold',
  );
  @override
  late final GeneratedColumn<double> lowStockThreshold =
      GeneratedColumn<double>(
        'low_stock_threshold',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creatorProfileIdMeta = const VerificationMeta(
    'creatorProfileId',
  );
  @override
  late final GeneratedColumn<String> creatorProfileId = GeneratedColumn<String>(
    'creator_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  static const VerificationMeta _ownerProfileIdMeta = const VerificationMeta(
    'ownerProfileId',
  );
  @override
  late final GeneratedColumn<String> ownerProfileId = GeneratedColumn<String>(
    'owner_profile_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profiles (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    categoryId,
    roomId,
    purchaseDate,
    purchasePrice,
    currentValue,
    replacementCost,
    condition,
    serialNumber,
    warrantyExpiration,
    containerId,
    barcode,
    storeUrl,
    notes,
    isInsured,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
    quantity,
    quantityUnit,
    lowStockThreshold,
    creatorProfileId,
    ownerProfileId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roomIdMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('current_value')) {
      context.handle(
        _currentValueMeta,
        currentValue.isAcceptableOrUnknown(
          data['current_value']!,
          _currentValueMeta,
        ),
      );
    }
    if (data.containsKey('replacement_cost')) {
      context.handle(
        _replacementCostMeta,
        replacementCost.isAcceptableOrUnknown(
          data['replacement_cost']!,
          _replacementCostMeta,
        ),
      );
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('warranty_expiration')) {
      context.handle(
        _warrantyExpirationMeta,
        warrantyExpiration.isAcceptableOrUnknown(
          data['warranty_expiration']!,
          _warrantyExpirationMeta,
        ),
      );
    }
    if (data.containsKey('container_id')) {
      context.handle(
        _containerIdMeta,
        containerId.isAcceptableOrUnknown(
          data['container_id']!,
          _containerIdMeta,
        ),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('store_url')) {
      context.handle(
        _storeUrlMeta,
        storeUrl.isAcceptableOrUnknown(data['store_url']!, _storeUrlMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_insured')) {
      context.handle(
        _isInsuredMeta,
        isInsured.isAcceptableOrUnknown(data['is_insured']!, _isInsuredMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('quantity_unit')) {
      context.handle(
        _quantityUnitMeta,
        quantityUnit.isAcceptableOrUnknown(
          data['quantity_unit']!,
          _quantityUnitMeta,
        ),
      );
    }
    if (data.containsKey('low_stock_threshold')) {
      context.handle(
        _lowStockThresholdMeta,
        lowStockThreshold.isAcceptableOrUnknown(
          data['low_stock_threshold']!,
          _lowStockThresholdMeta,
        ),
      );
    }
    if (data.containsKey('creator_profile_id')) {
      context.handle(
        _creatorProfileIdMeta,
        creatorProfileId.isAcceptableOrUnknown(
          data['creator_profile_id']!,
          _creatorProfileIdMeta,
        ),
      );
    }
    if (data.containsKey('owner_profile_id')) {
      context.handle(
        _ownerProfileIdMeta,
        ownerProfileId.isAcceptableOrUnknown(
          data['owner_profile_id']!,
          _ownerProfileIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      ),
      currentValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_value'],
      ),
      replacementCost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}replacement_cost'],
      ),
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      warrantyExpiration: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}warranty_expiration'],
      ),
      containerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      storeUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_url'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isInsured: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_insured'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      quantityUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quantity_unit'],
      ),
      lowStockThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}low_stock_threshold'],
      ),
      creatorProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_profile_id'],
      ),
      ownerProfileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_profile_id'],
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }
}

class Item extends DataClass implements Insertable<Item> {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String roomId;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentValue;
  final double? replacementCost;
  final String? condition;
  final String? serialNumber;
  final DateTime? warrantyExpiration;
  final String? containerId;
  final String? barcode;
  final String? storeUrl;
  final String? notes;
  final bool isInsured;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  final double? quantity;
  final String? quantityUnit;
  final double? lowStockThreshold;
  final String? creatorProfileId;
  final String? ownerProfileId;
  const Item({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.roomId,
    this.purchaseDate,
    this.purchasePrice,
    this.currentValue,
    this.replacementCost,
    this.condition,
    this.serialNumber,
    this.warrantyExpiration,
    this.containerId,
    this.barcode,
    this.storeUrl,
    this.notes,
    required this.isInsured,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
    this.quantity,
    this.quantityUnit,
    this.lowStockThreshold,
    this.creatorProfileId,
    this.ownerProfileId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['category_id'] = Variable<String>(categoryId);
    map['room_id'] = Variable<String>(roomId);
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    if (!nullToAbsent || currentValue != null) {
      map['current_value'] = Variable<double>(currentValue);
    }
    if (!nullToAbsent || replacementCost != null) {
      map['replacement_cost'] = Variable<double>(replacementCost);
    }
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    if (!nullToAbsent || warrantyExpiration != null) {
      map['warranty_expiration'] = Variable<DateTime>(warrantyExpiration);
    }
    if (!nullToAbsent || containerId != null) {
      map['container_id'] = Variable<String>(containerId);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || storeUrl != null) {
      map['store_url'] = Variable<String>(storeUrl);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_insured'] = Variable<bool>(isInsured);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || quantityUnit != null) {
      map['quantity_unit'] = Variable<String>(quantityUnit);
    }
    if (!nullToAbsent || lowStockThreshold != null) {
      map['low_stock_threshold'] = Variable<double>(lowStockThreshold);
    }
    if (!nullToAbsent || creatorProfileId != null) {
      map['creator_profile_id'] = Variable<String>(creatorProfileId);
    }
    if (!nullToAbsent || ownerProfileId != null) {
      map['owner_profile_id'] = Variable<String>(ownerProfileId);
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      categoryId: Value(categoryId),
      roomId: Value(roomId),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      currentValue: currentValue == null && nullToAbsent
          ? const Value.absent()
          : Value(currentValue),
      replacementCost: replacementCost == null && nullToAbsent
          ? const Value.absent()
          : Value(replacementCost),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      warrantyExpiration: warrantyExpiration == null && nullToAbsent
          ? const Value.absent()
          : Value(warrantyExpiration),
      containerId: containerId == null && nullToAbsent
          ? const Value.absent()
          : Value(containerId),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      storeUrl: storeUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(storeUrl),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isInsured: Value(isInsured),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      quantityUnit: quantityUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityUnit),
      lowStockThreshold: lowStockThreshold == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockThreshold),
      creatorProfileId: creatorProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorProfileId),
      ownerProfileId: ownerProfileId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerProfileId),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      roomId: serializer.fromJson<String>(json['roomId']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      currentValue: serializer.fromJson<double?>(json['currentValue']),
      replacementCost: serializer.fromJson<double?>(json['replacementCost']),
      condition: serializer.fromJson<String?>(json['condition']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      warrantyExpiration: serializer.fromJson<DateTime?>(
        json['warrantyExpiration'],
      ),
      containerId: serializer.fromJson<String?>(json['containerId']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      storeUrl: serializer.fromJson<String?>(json['storeUrl']),
      notes: serializer.fromJson<String?>(json['notes']),
      isInsured: serializer.fromJson<bool>(json['isInsured']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      quantityUnit: serializer.fromJson<String?>(json['quantityUnit']),
      lowStockThreshold: serializer.fromJson<double?>(
        json['lowStockThreshold'],
      ),
      creatorProfileId: serializer.fromJson<String?>(json['creatorProfileId']),
      ownerProfileId: serializer.fromJson<String?>(json['ownerProfileId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'categoryId': serializer.toJson<String>(categoryId),
      'roomId': serializer.toJson<String>(roomId),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'currentValue': serializer.toJson<double?>(currentValue),
      'replacementCost': serializer.toJson<double?>(replacementCost),
      'condition': serializer.toJson<String?>(condition),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'warrantyExpiration': serializer.toJson<DateTime?>(warrantyExpiration),
      'containerId': serializer.toJson<String?>(containerId),
      'barcode': serializer.toJson<String?>(barcode),
      'storeUrl': serializer.toJson<String?>(storeUrl),
      'notes': serializer.toJson<String?>(notes),
      'isInsured': serializer.toJson<bool>(isInsured),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'quantity': serializer.toJson<double?>(quantity),
      'quantityUnit': serializer.toJson<String?>(quantityUnit),
      'lowStockThreshold': serializer.toJson<double?>(lowStockThreshold),
      'creatorProfileId': serializer.toJson<String?>(creatorProfileId),
      'ownerProfileId': serializer.toJson<String?>(ownerProfileId),
    };
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    String? roomId,
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<double?> purchasePrice = const Value.absent(),
    Value<double?> currentValue = const Value.absent(),
    Value<double?> replacementCost = const Value.absent(),
    Value<String?> condition = const Value.absent(),
    Value<String?> serialNumber = const Value.absent(),
    Value<DateTime?> warrantyExpiration = const Value.absent(),
    Value<String?> containerId = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> storeUrl = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isInsured,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
    Value<double?> quantity = const Value.absent(),
    Value<String?> quantityUnit = const Value.absent(),
    Value<double?> lowStockThreshold = const Value.absent(),
    Value<String?> creatorProfileId = const Value.absent(),
    Value<String?> ownerProfileId = const Value.absent(),
  }) => Item(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    roomId: roomId ?? this.roomId,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    purchasePrice: purchasePrice.present
        ? purchasePrice.value
        : this.purchasePrice,
    currentValue: currentValue.present ? currentValue.value : this.currentValue,
    replacementCost: replacementCost.present
        ? replacementCost.value
        : this.replacementCost,
    condition: condition.present ? condition.value : this.condition,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    warrantyExpiration: warrantyExpiration.present
        ? warrantyExpiration.value
        : this.warrantyExpiration,
    containerId: containerId.present ? containerId.value : this.containerId,
    barcode: barcode.present ? barcode.value : this.barcode,
    storeUrl: storeUrl.present ? storeUrl.value : this.storeUrl,
    notes: notes.present ? notes.value : this.notes,
    isInsured: isInsured ?? this.isInsured,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    quantity: quantity.present ? quantity.value : this.quantity,
    quantityUnit: quantityUnit.present ? quantityUnit.value : this.quantityUnit,
    lowStockThreshold: lowStockThreshold.present
        ? lowStockThreshold.value
        : this.lowStockThreshold,
    creatorProfileId: creatorProfileId.present
        ? creatorProfileId.value
        : this.creatorProfileId,
    ownerProfileId: ownerProfileId.present
        ? ownerProfileId.value
        : this.ownerProfileId,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      replacementCost: data.replacementCost.present
          ? data.replacementCost.value
          : this.replacementCost,
      condition: data.condition.present ? data.condition.value : this.condition,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      warrantyExpiration: data.warrantyExpiration.present
          ? data.warrantyExpiration.value
          : this.warrantyExpiration,
      containerId: data.containerId.present
          ? data.containerId.value
          : this.containerId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      storeUrl: data.storeUrl.present ? data.storeUrl.value : this.storeUrl,
      notes: data.notes.present ? data.notes.value : this.notes,
      isInsured: data.isInsured.present ? data.isInsured.value : this.isInsured,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      quantityUnit: data.quantityUnit.present
          ? data.quantityUnit.value
          : this.quantityUnit,
      lowStockThreshold: data.lowStockThreshold.present
          ? data.lowStockThreshold.value
          : this.lowStockThreshold,
      creatorProfileId: data.creatorProfileId.present
          ? data.creatorProfileId.value
          : this.creatorProfileId,
      ownerProfileId: data.ownerProfileId.present
          ? data.ownerProfileId.value
          : this.ownerProfileId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('roomId: $roomId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('currentValue: $currentValue, ')
          ..write('replacementCost: $replacementCost, ')
          ..write('condition: $condition, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('warrantyExpiration: $warrantyExpiration, ')
          ..write('containerId: $containerId, ')
          ..write('barcode: $barcode, ')
          ..write('storeUrl: $storeUrl, ')
          ..write('notes: $notes, ')
          ..write('isInsured: $isInsured, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('quantity: $quantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('creatorProfileId: $creatorProfileId, ')
          ..write('ownerProfileId: $ownerProfileId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    categoryId,
    roomId,
    purchaseDate,
    purchasePrice,
    currentValue,
    replacementCost,
    condition,
    serialNumber,
    warrantyExpiration,
    containerId,
    barcode,
    storeUrl,
    notes,
    isInsured,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
    quantity,
    quantityUnit,
    lowStockThreshold,
    creatorProfileId,
    ownerProfileId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.categoryId == this.categoryId &&
          other.roomId == this.roomId &&
          other.purchaseDate == this.purchaseDate &&
          other.purchasePrice == this.purchasePrice &&
          other.currentValue == this.currentValue &&
          other.replacementCost == this.replacementCost &&
          other.condition == this.condition &&
          other.serialNumber == this.serialNumber &&
          other.warrantyExpiration == this.warrantyExpiration &&
          other.containerId == this.containerId &&
          other.barcode == this.barcode &&
          other.storeUrl == this.storeUrl &&
          other.notes == this.notes &&
          other.isInsured == this.isInsured &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.quantity == this.quantity &&
          other.quantityUnit == this.quantityUnit &&
          other.lowStockThreshold == this.lowStockThreshold &&
          other.creatorProfileId == this.creatorProfileId &&
          other.ownerProfileId == this.ownerProfileId);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> description;
  final Value<String> categoryId;
  final Value<String> roomId;
  final Value<DateTime?> purchaseDate;
  final Value<double?> purchasePrice;
  final Value<double?> currentValue;
  final Value<double?> replacementCost;
  final Value<String?> condition;
  final Value<String?> serialNumber;
  final Value<DateTime?> warrantyExpiration;
  final Value<String?> containerId;
  final Value<String?> barcode;
  final Value<String?> storeUrl;
  final Value<String?> notes;
  final Value<bool> isInsured;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<double?> quantity;
  final Value<String?> quantityUnit;
  final Value<double?> lowStockThreshold;
  final Value<String?> creatorProfileId;
  final Value<String?> ownerProfileId;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.replacementCost = const Value.absent(),
    this.condition = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.warrantyExpiration = const Value.absent(),
    this.containerId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.storeUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.isInsured = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.creatorProfileId = const Value.absent(),
    this.ownerProfileId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String categoryId,
    required String roomId,
    this.purchaseDate = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.replacementCost = const Value.absent(),
    this.condition = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.warrantyExpiration = const Value.absent(),
    this.containerId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.storeUrl = const Value.absent(),
    this.notes = const Value.absent(),
    this.isInsured = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.quantity = const Value.absent(),
    this.quantityUnit = const Value.absent(),
    this.lowStockThreshold = const Value.absent(),
    this.creatorProfileId = const Value.absent(),
    this.ownerProfileId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       categoryId = Value(categoryId),
       roomId = Value(roomId),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Item> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? categoryId,
    Expression<String>? roomId,
    Expression<DateTime>? purchaseDate,
    Expression<double>? purchasePrice,
    Expression<double>? currentValue,
    Expression<double>? replacementCost,
    Expression<String>? condition,
    Expression<String>? serialNumber,
    Expression<DateTime>? warrantyExpiration,
    Expression<String>? containerId,
    Expression<String>? barcode,
    Expression<String>? storeUrl,
    Expression<String>? notes,
    Expression<bool>? isInsured,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<double>? quantity,
    Expression<String>? quantityUnit,
    Expression<double>? lowStockThreshold,
    Expression<String>? creatorProfileId,
    Expression<String>? ownerProfileId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (roomId != null) 'room_id': roomId,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (currentValue != null) 'current_value': currentValue,
      if (replacementCost != null) 'replacement_cost': replacementCost,
      if (condition != null) 'condition': condition,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (warrantyExpiration != null) 'warranty_expiration': warrantyExpiration,
      if (containerId != null) 'container_id': containerId,
      if (barcode != null) 'barcode': barcode,
      if (storeUrl != null) 'store_url': storeUrl,
      if (notes != null) 'notes': notes,
      if (isInsured != null) 'is_insured': isInsured,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (quantity != null) 'quantity': quantity,
      if (quantityUnit != null) 'quantity_unit': quantityUnit,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (creatorProfileId != null) 'creator_profile_id': creatorProfileId,
      if (ownerProfileId != null) 'owner_profile_id': ownerProfileId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? description,
    Value<String>? categoryId,
    Value<String>? roomId,
    Value<DateTime?>? purchaseDate,
    Value<double?>? purchasePrice,
    Value<double?>? currentValue,
    Value<double?>? replacementCost,
    Value<String?>? condition,
    Value<String?>? serialNumber,
    Value<DateTime?>? warrantyExpiration,
    Value<String?>? containerId,
    Value<String?>? barcode,
    Value<String?>? storeUrl,
    Value<String?>? notes,
    Value<bool>? isInsured,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<double?>? quantity,
    Value<String?>? quantityUnit,
    Value<double?>? lowStockThreshold,
    Value<String?>? creatorProfileId,
    Value<String?>? ownerProfileId,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      roomId: roomId ?? this.roomId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentValue: currentValue ?? this.currentValue,
      replacementCost: replacementCost ?? this.replacementCost,
      condition: condition ?? this.condition,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyExpiration: warrantyExpiration ?? this.warrantyExpiration,
      containerId: containerId ?? this.containerId,
      barcode: barcode ?? this.barcode,
      storeUrl: storeUrl ?? this.storeUrl,
      notes: notes ?? this.notes,
      isInsured: isInsured ?? this.isInsured,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      creatorProfileId: creatorProfileId ?? this.creatorProfileId,
      ownerProfileId: ownerProfileId ?? this.ownerProfileId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (replacementCost.present) {
      map['replacement_cost'] = Variable<double>(replacementCost.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (warrantyExpiration.present) {
      map['warranty_expiration'] = Variable<DateTime>(warrantyExpiration.value);
    }
    if (containerId.present) {
      map['container_id'] = Variable<String>(containerId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (storeUrl.present) {
      map['store_url'] = Variable<String>(storeUrl.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isInsured.present) {
      map['is_insured'] = Variable<bool>(isInsured.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (quantityUnit.present) {
      map['quantity_unit'] = Variable<String>(quantityUnit.value);
    }
    if (lowStockThreshold.present) {
      map['low_stock_threshold'] = Variable<double>(lowStockThreshold.value);
    }
    if (creatorProfileId.present) {
      map['creator_profile_id'] = Variable<String>(creatorProfileId.value);
    }
    if (ownerProfileId.present) {
      map['owner_profile_id'] = Variable<String>(ownerProfileId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('categoryId: $categoryId, ')
          ..write('roomId: $roomId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('currentValue: $currentValue, ')
          ..write('replacementCost: $replacementCost, ')
          ..write('condition: $condition, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('warrantyExpiration: $warrantyExpiration, ')
          ..write('containerId: $containerId, ')
          ..write('barcode: $barcode, ')
          ..write('storeUrl: $storeUrl, ')
          ..write('notes: $notes, ')
          ..write('isInsured: $isInsured, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('quantity: $quantity, ')
          ..write('quantityUnit: $quantityUnit, ')
          ..write('lowStockThreshold: $lowStockThreshold, ')
          ..write('creatorProfileId: $creatorProfileId, ')
          ..write('ownerProfileId: $ownerProfileId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final int? color;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Tag({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.color = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int?>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemTagsTable extends ItemTags with TableInfo<$ItemTagsTable, ItemTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    itemId,
    tagId,
    createdAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ItemTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, tagId};
  @override
  ItemTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemTag(
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ItemTagsTable createAlias(String alias) {
    return $ItemTagsTable(attachedDatabase, alias);
  }
}

class ItemTag extends DataClass implements Insertable<ItemTag> {
  final String itemId;
  final String tagId;
  final DateTime createdAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const ItemTag({
    required this.itemId,
    required this.tagId,
    required this.createdAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['tag_id'] = Variable<String>(tagId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ItemTagsCompanion toCompanion(bool nullToAbsent) {
    return ItemTagsCompanion(
      itemId: Value(itemId),
      tagId: Value(tagId),
      createdAt: Value(createdAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory ItemTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemTag(
      itemId: serializer.fromJson<String>(json['itemId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'tagId': serializer.toJson<String>(tagId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ItemTag copyWith({
    String? itemId,
    String? tagId,
    DateTime? createdAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => ItemTag(
    itemId: itemId ?? this.itemId,
    tagId: tagId ?? this.tagId,
    createdAt: createdAt ?? this.createdAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ItemTag copyWithCompanion(ItemTagsCompanion data) {
    return ItemTag(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemTag(')
          ..write('itemId: $itemId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, tagId, createdAt, nodeId, hlc, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemTag &&
          other.itemId == this.itemId &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class ItemTagsCompanion extends UpdateCompanion<ItemTag> {
  final Value<String> itemId;
  final Value<String> tagId;
  final Value<DateTime> createdAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ItemTagsCompanion({
    this.itemId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemTagsCompanion.insert({
    required String itemId,
    required String tagId,
    required DateTime createdAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       tagId = Value(tagId),
       createdAt = Value(createdAt);
  static Insertable<ItemTag> custom({
    Expression<String>? itemId,
    Expression<String>? tagId,
    Expression<DateTime>? createdAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemTagsCompanion copyWith({
    Value<String>? itemId,
    Value<String>? tagId,
    Value<DateTime>? createdAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ItemTagsCompanion(
      itemId: itemId ?? this.itemId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemTagsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotosTable extends Photos with TableInfo<$PhotosTable, Photo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('camera'),
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    filePath,
    isPrimary,
    source,
    capturedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Photo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Photo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Photo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PhotosTable createAlias(String alias) {
    return $PhotosTable(attachedDatabase, alias);
  }
}

class Photo extends DataClass implements Insertable<Photo> {
  final String id;
  final String itemId;
  final String filePath;
  final bool isPrimary;
  final String source;
  final DateTime capturedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Photo({
    required this.id,
    required this.itemId,
    required this.filePath,
    required this.isPrimary,
    required this.source,
    required this.capturedAt,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['file_path'] = Variable<String>(filePath);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['source'] = Variable<String>(source);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PhotosCompanion toCompanion(bool nullToAbsent) {
    return PhotosCompanion(
      id: Value(id),
      itemId: Value(itemId),
      filePath: Value(filePath),
      isPrimary: Value(isPrimary),
      source: Value(source),
      capturedAt: Value(capturedAt),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Photo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Photo(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      source: serializer.fromJson<String>(json['source']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'filePath': serializer.toJson<String>(filePath),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'source': serializer.toJson<String>(source),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Photo copyWith({
    String? id,
    String? itemId,
    String? filePath,
    bool? isPrimary,
    String? source,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Photo(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    filePath: filePath ?? this.filePath,
    isPrimary: isPrimary ?? this.isPrimary,
    source: source ?? this.source,
    capturedAt: capturedAt ?? this.capturedAt,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Photo copyWithCompanion(PhotosCompanion data) {
    return Photo(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      source: data.source.present ? data.source.value : this.source,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Photo(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('filePath: $filePath, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('source: $source, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    filePath,
    isPrimary,
    source,
    capturedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Photo &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.filePath == this.filePath &&
          other.isPrimary == this.isPrimary &&
          other.source == this.source &&
          other.capturedAt == this.capturedAt &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class PhotosCompanion extends UpdateCompanion<Photo> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> filePath;
  final Value<bool> isPrimary;
  final Value<String> source;
  final Value<DateTime> capturedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PhotosCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.source = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotosCompanion.insert({
    required String id,
    required String itemId,
    required String filePath,
    this.isPrimary = const Value.absent(),
    this.source = const Value.absent(),
    required DateTime capturedAt,
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       filePath = Value(filePath),
       capturedAt = Value(capturedAt),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Photo> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? filePath,
    Expression<bool>? isPrimary,
    Expression<String>? source,
    Expression<DateTime>? capturedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (filePath != null) 'file_path': filePath,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (source != null) 'source': source,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? filePath,
    Value<bool>? isPrimary,
    Value<String>? source,
    Value<DateTime>? capturedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PhotosCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      filePath: filePath ?? this.filePath,
      isPrimary: isPrimary ?? this.isPrimary,
      source: source ?? this.source,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotosCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('filePath: $filePath, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('source: $source, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeNameMeta = const VerificationMeta(
    'storeName',
  );
  @override
  late final GeneratedColumn<String> storeName = GeneratedColumn<String>(
    'store_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    photoPath,
    storeName,
    purchaseDate,
    totalAmount,
    ocrText,
    nodeId,
    hlc,
    isDeleted,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_photoPathMeta);
    }
    if (data.containsKey('store_name')) {
      context.handle(
        _storeNameMeta,
        storeName.isAcceptableOrUnknown(data['store_name']!, _storeNameMeta),
      );
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      )!,
      storeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_name'],
      ),
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      ),
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final String id;
  final String? itemId;
  final String photoPath;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String? ocrText;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  final DateTime createdAt;
  const Receipt({
    required this.id,
    this.itemId,
    required this.photoPath,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.ocrText,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['photo_path'] = Variable<String>(photoPath);
    if (!nullToAbsent || storeName != null) {
      map['store_name'] = Variable<String>(storeName);
    }
    if (!nullToAbsent || purchaseDate != null) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate);
    }
    if (!nullToAbsent || totalAmount != null) {
      map['total_amount'] = Variable<double>(totalAmount);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      photoPath: Value(photoPath),
      storeName: storeName == null && nullToAbsent
          ? const Value.absent()
          : Value(storeName),
      purchaseDate: purchaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseDate),
      totalAmount: totalAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(totalAmount),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      photoPath: serializer.fromJson<String>(json['photoPath']),
      storeName: serializer.fromJson<String?>(json['storeName']),
      purchaseDate: serializer.fromJson<DateTime?>(json['purchaseDate']),
      totalAmount: serializer.fromJson<double?>(json['totalAmount']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String?>(itemId),
      'photoPath': serializer.toJson<String>(photoPath),
      'storeName': serializer.toJson<String?>(storeName),
      'purchaseDate': serializer.toJson<DateTime?>(purchaseDate),
      'totalAmount': serializer.toJson<double?>(totalAmount),
      'ocrText': serializer.toJson<String?>(ocrText),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Receipt copyWith({
    String? id,
    Value<String?> itemId = const Value.absent(),
    String? photoPath,
    Value<String?> storeName = const Value.absent(),
    Value<DateTime?> purchaseDate = const Value.absent(),
    Value<double?> totalAmount = const Value.absent(),
    Value<String?> ocrText = const Value.absent(),
    String? nodeId,
    String? hlc,
    bool? isDeleted,
    DateTime? createdAt,
  }) => Receipt(
    id: id ?? this.id,
    itemId: itemId.present ? itemId.value : this.itemId,
    photoPath: photoPath ?? this.photoPath,
    storeName: storeName.present ? storeName.value : this.storeName,
    purchaseDate: purchaseDate.present ? purchaseDate.value : this.purchaseDate,
    totalAmount: totalAmount.present ? totalAmount.value : this.totalAmount,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      storeName: data.storeName.present ? data.storeName.value : this.storeName,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('photoPath: $photoPath, ')
          ..write('storeName: $storeName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('ocrText: $ocrText, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    photoPath,
    storeName,
    purchaseDate,
    totalAmount,
    ocrText,
    nodeId,
    hlc,
    isDeleted,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.photoPath == this.photoPath &&
          other.storeName == this.storeName &&
          other.purchaseDate == this.purchaseDate &&
          other.totalAmount == this.totalAmount &&
          other.ocrText == this.ocrText &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<String> id;
  final Value<String?> itemId;
  final Value<String> photoPath;
  final Value<String?> storeName;
  final Value<DateTime?> purchaseDate;
  final Value<double?> totalAmount;
  final Value<String?> ocrText;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.storeName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required String id,
    this.itemId = const Value.absent(),
    required String photoPath,
    this.storeName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       photoPath = Value(photoPath),
       createdAt = Value(createdAt);
  static Insertable<Receipt> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? photoPath,
    Expression<String>? storeName,
    Expression<DateTime>? purchaseDate,
    Expression<double>? totalAmount,
    Expression<String>? ocrText,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (photoPath != null) 'photo_path': photoPath,
      if (storeName != null) 'store_name': storeName,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (ocrText != null) 'ocr_text': ocrText,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<String>? id,
    Value<String?>? itemId,
    Value<String>? photoPath,
    Value<String?>? storeName,
    Value<DateTime?>? purchaseDate,
    Value<double?>? totalAmount,
    Value<String?>? ocrText,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      photoPath: photoPath ?? this.photoPath,
      storeName: storeName ?? this.storeName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      ocrText: ocrText ?? this.ocrText,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (storeName.present) {
      map['store_name'] = Variable<String>(storeName.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('photoPath: $photoPath, ')
          ..write('storeName: $storeName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('ocrText: $ocrText, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PriceHistoryEntriesTable extends PriceHistoryEntries
    with TableInfo<$PriceHistoryEntriesTable, PriceHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceHistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    price,
    source,
    recordedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PriceHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PriceHistoryEntriesTable createAlias(String alias) {
    return $PriceHistoryEntriesTable(attachedDatabase, alias);
  }
}

class PriceHistoryEntry extends DataClass
    implements Insertable<PriceHistoryEntry> {
  final String id;
  final String itemId;
  final double price;
  final String source;
  final DateTime recordedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const PriceHistoryEntry({
    required this.id,
    required this.itemId,
    required this.price,
    required this.source,
    required this.recordedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['price'] = Variable<double>(price);
    map['source'] = Variable<String>(source);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PriceHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return PriceHistoryEntriesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      price: Value(price),
      source: Value(source),
      recordedAt: Value(recordedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory PriceHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      price: serializer.fromJson<double>(json['price']),
      source: serializer.fromJson<String>(json['source']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'price': serializer.toJson<double>(price),
      'source': serializer.toJson<String>(source),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  PriceHistoryEntry copyWith({
    String? id,
    String? itemId,
    double? price,
    String? source,
    DateTime? recordedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => PriceHistoryEntry(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    price: price ?? this.price,
    source: source ?? this.source,
    recordedAt: recordedAt ?? this.recordedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  PriceHistoryEntry copyWithCompanion(PriceHistoryEntriesCompanion data) {
    return PriceHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      price: data.price.present ? data.price.value : this.price,
      source: data.source.present ? data.source.value : this.source,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryEntry(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price, ')
          ..write('source: $source, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    price,
    source,
    recordedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceHistoryEntry &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.price == this.price &&
          other.source == this.source &&
          other.recordedAt == this.recordedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class PriceHistoryEntriesCompanion extends UpdateCompanion<PriceHistoryEntry> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<double> price;
  final Value<String> source;
  final Value<DateTime> recordedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PriceHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.price = const Value.absent(),
    this.source = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PriceHistoryEntriesCompanion.insert({
    required String id,
    required String itemId,
    required double price,
    required String source,
    required DateTime recordedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       price = Value(price),
       source = Value(source),
       recordedAt = Value(recordedAt);
  static Insertable<PriceHistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<double>? price,
    Expression<String>? source,
    Expression<DateTime>? recordedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (price != null) 'price': price,
      if (source != null) 'source': source,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PriceHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<double>? price,
    Value<String>? source,
    Value<DateTime>? recordedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PriceHistoryEntriesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      source: source ?? this.source,
      recordedAt: recordedAt ?? this.recordedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price, ')
          ..write('source: $source, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PoliciesTable extends Policies with TableInfo<$PoliciesTable, Policy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PoliciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _propertyIdMeta = const VerificationMeta(
    'propertyId',
  );
  @override
  late final GeneratedColumn<String> propertyId = GeneratedColumn<String>(
    'property_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES properties (id)',
    ),
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _policyNumberMeta = const VerificationMeta(
    'policyNumber',
  );
  @override
  late final GeneratedColumn<String> policyNumber = GeneratedColumn<String>(
    'policy_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverageAmountMeta = const VerificationMeta(
    'coverageAmount',
  );
  @override
  late final GeneratedColumn<double> coverageAmount = GeneratedColumn<double>(
    'coverage_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deductibleMeta = const VerificationMeta(
    'deductible',
  );
  @override
  late final GeneratedColumn<double> deductible = GeneratedColumn<double>(
    'deductible',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _premiumMeta = const VerificationMeta(
    'premium',
  );
  @override
  late final GeneratedColumn<double> premium = GeneratedColumn<double>(
    'premium',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    propertyId,
    provider,
    policyNumber,
    coverageAmount,
    deductible,
    premium,
    expiryDate,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'policies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Policy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('property_id')) {
      context.handle(
        _propertyIdMeta,
        propertyId.isAcceptableOrUnknown(data['property_id']!, _propertyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_propertyIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('policy_number')) {
      context.handle(
        _policyNumberMeta,
        policyNumber.isAcceptableOrUnknown(
          data['policy_number']!,
          _policyNumberMeta,
        ),
      );
    }
    if (data.containsKey('coverage_amount')) {
      context.handle(
        _coverageAmountMeta,
        coverageAmount.isAcceptableOrUnknown(
          data['coverage_amount']!,
          _coverageAmountMeta,
        ),
      );
    }
    if (data.containsKey('deductible')) {
      context.handle(
        _deductibleMeta,
        deductible.isAcceptableOrUnknown(data['deductible']!, _deductibleMeta),
      );
    }
    if (data.containsKey('premium')) {
      context.handle(
        _premiumMeta,
        premium.isAcceptableOrUnknown(data['premium']!, _premiumMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Policy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Policy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      propertyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}property_id'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      policyNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}policy_number'],
      ),
      coverageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}coverage_amount'],
      ),
      deductible: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deductible'],
      ),
      premium: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}premium'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $PoliciesTable createAlias(String alias) {
    return $PoliciesTable(attachedDatabase, alias);
  }
}

class Policy extends DataClass implements Insertable<Policy> {
  final String id;
  final String propertyId;
  final String provider;
  final String? policyNumber;
  final double? coverageAmount;
  final double? deductible;
  final double? premium;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Policy({
    required this.id,
    required this.propertyId,
    required this.provider,
    this.policyNumber,
    this.coverageAmount,
    this.deductible,
    this.premium,
    this.expiryDate,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['property_id'] = Variable<String>(propertyId);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || policyNumber != null) {
      map['policy_number'] = Variable<String>(policyNumber);
    }
    if (!nullToAbsent || coverageAmount != null) {
      map['coverage_amount'] = Variable<double>(coverageAmount);
    }
    if (!nullToAbsent || deductible != null) {
      map['deductible'] = Variable<double>(deductible);
    }
    if (!nullToAbsent || premium != null) {
      map['premium'] = Variable<double>(premium);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  PoliciesCompanion toCompanion(bool nullToAbsent) {
    return PoliciesCompanion(
      id: Value(id),
      propertyId: Value(propertyId),
      provider: Value(provider),
      policyNumber: policyNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(policyNumber),
      coverageAmount: coverageAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(coverageAmount),
      deductible: deductible == null && nullToAbsent
          ? const Value.absent()
          : Value(deductible),
      premium: premium == null && nullToAbsent
          ? const Value.absent()
          : Value(premium),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Policy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Policy(
      id: serializer.fromJson<String>(json['id']),
      propertyId: serializer.fromJson<String>(json['propertyId']),
      provider: serializer.fromJson<String>(json['provider']),
      policyNumber: serializer.fromJson<String?>(json['policyNumber']),
      coverageAmount: serializer.fromJson<double?>(json['coverageAmount']),
      deductible: serializer.fromJson<double?>(json['deductible']),
      premium: serializer.fromJson<double?>(json['premium']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'propertyId': serializer.toJson<String>(propertyId),
      'provider': serializer.toJson<String>(provider),
      'policyNumber': serializer.toJson<String?>(policyNumber),
      'coverageAmount': serializer.toJson<double?>(coverageAmount),
      'deductible': serializer.toJson<double?>(deductible),
      'premium': serializer.toJson<double?>(premium),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Policy copyWith({
    String? id,
    String? propertyId,
    String? provider,
    Value<String?> policyNumber = const Value.absent(),
    Value<double?> coverageAmount = const Value.absent(),
    Value<double?> deductible = const Value.absent(),
    Value<double?> premium = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Policy(
    id: id ?? this.id,
    propertyId: propertyId ?? this.propertyId,
    provider: provider ?? this.provider,
    policyNumber: policyNumber.present ? policyNumber.value : this.policyNumber,
    coverageAmount: coverageAmount.present
        ? coverageAmount.value
        : this.coverageAmount,
    deductible: deductible.present ? deductible.value : this.deductible,
    premium: premium.present ? premium.value : this.premium,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Policy copyWithCompanion(PoliciesCompanion data) {
    return Policy(
      id: data.id.present ? data.id.value : this.id,
      propertyId: data.propertyId.present
          ? data.propertyId.value
          : this.propertyId,
      provider: data.provider.present ? data.provider.value : this.provider,
      policyNumber: data.policyNumber.present
          ? data.policyNumber.value
          : this.policyNumber,
      coverageAmount: data.coverageAmount.present
          ? data.coverageAmount.value
          : this.coverageAmount,
      deductible: data.deductible.present
          ? data.deductible.value
          : this.deductible,
      premium: data.premium.present ? data.premium.value : this.premium,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Policy(')
          ..write('id: $id, ')
          ..write('propertyId: $propertyId, ')
          ..write('provider: $provider, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('coverageAmount: $coverageAmount, ')
          ..write('deductible: $deductible, ')
          ..write('premium: $premium, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    propertyId,
    provider,
    policyNumber,
    coverageAmount,
    deductible,
    premium,
    expiryDate,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Policy &&
          other.id == this.id &&
          other.propertyId == this.propertyId &&
          other.provider == this.provider &&
          other.policyNumber == this.policyNumber &&
          other.coverageAmount == this.coverageAmount &&
          other.deductible == this.deductible &&
          other.premium == this.premium &&
          other.expiryDate == this.expiryDate &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class PoliciesCompanion extends UpdateCompanion<Policy> {
  final Value<String> id;
  final Value<String> propertyId;
  final Value<String> provider;
  final Value<String?> policyNumber;
  final Value<double?> coverageAmount;
  final Value<double?> deductible;
  final Value<double?> premium;
  final Value<DateTime?> expiryDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const PoliciesCompanion({
    this.id = const Value.absent(),
    this.propertyId = const Value.absent(),
    this.provider = const Value.absent(),
    this.policyNumber = const Value.absent(),
    this.coverageAmount = const Value.absent(),
    this.deductible = const Value.absent(),
    this.premium = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoliciesCompanion.insert({
    required String id,
    required String propertyId,
    required String provider,
    this.policyNumber = const Value.absent(),
    this.coverageAmount = const Value.absent(),
    this.deductible = const Value.absent(),
    this.premium = const Value.absent(),
    this.expiryDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       propertyId = Value(propertyId),
       provider = Value(provider),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Policy> custom({
    Expression<String>? id,
    Expression<String>? propertyId,
    Expression<String>? provider,
    Expression<String>? policyNumber,
    Expression<double>? coverageAmount,
    Expression<double>? deductible,
    Expression<double>? premium,
    Expression<DateTime>? expiryDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (propertyId != null) 'property_id': propertyId,
      if (provider != null) 'provider': provider,
      if (policyNumber != null) 'policy_number': policyNumber,
      if (coverageAmount != null) 'coverage_amount': coverageAmount,
      if (deductible != null) 'deductible': deductible,
      if (premium != null) 'premium': premium,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoliciesCompanion copyWith({
    Value<String>? id,
    Value<String>? propertyId,
    Value<String>? provider,
    Value<String?>? policyNumber,
    Value<double?>? coverageAmount,
    Value<double?>? deductible,
    Value<double?>? premium,
    Value<DateTime?>? expiryDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return PoliciesCompanion(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      coverageAmount: coverageAmount ?? this.coverageAmount,
      deductible: deductible ?? this.deductible,
      premium: premium ?? this.premium,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (propertyId.present) {
      map['property_id'] = Variable<String>(propertyId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (policyNumber.present) {
      map['policy_number'] = Variable<String>(policyNumber.value);
    }
    if (coverageAmount.present) {
      map['coverage_amount'] = Variable<double>(coverageAmount.value);
    }
    if (deductible.present) {
      map['deductible'] = Variable<double>(deductible.value);
    }
    if (premium.present) {
      map['premium'] = Variable<double>(premium.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoliciesCompanion(')
          ..write('id: $id, ')
          ..write('propertyId: $propertyId, ')
          ..write('provider: $provider, ')
          ..write('policyNumber: $policyNumber, ')
          ..write('coverageAmount: $coverageAmount, ')
          ..write('deductible: $deductible, ')
          ..write('premium: $premium, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MaintenanceLogsTable extends MaintenanceLogs
    with TableInfo<$MaintenanceLogsTable, MaintenanceLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaintenanceLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _propertyIdMeta = const VerificationMeta(
    'propertyId',
  );
  @override
  late final GeneratedColumn<String> propertyId = GeneratedColumn<String>(
    'property_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES properties (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 300,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
    'cost',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _performedAtMeta = const VerificationMeta(
    'performedAt',
  );
  @override
  late final GeneratedColumn<DateTime> performedAt = GeneratedColumn<DateTime>(
    'performed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextDueAtMeta = const VerificationMeta(
    'nextDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueAt = GeneratedColumn<DateTime>(
    'next_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servicedByMeta = const VerificationMeta(
    'servicedBy',
  );
  @override
  late final GeneratedColumn<String> servicedBy = GeneratedColumn<String>(
    'serviced_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    propertyId,
    title,
    description,
    cost,
    performedAt,
    nextDueAt,
    servicedBy,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'maintenance_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MaintenanceLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('property_id')) {
      context.handle(
        _propertyIdMeta,
        propertyId.isAcceptableOrUnknown(data['property_id']!, _propertyIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cost')) {
      context.handle(
        _costMeta,
        cost.isAcceptableOrUnknown(data['cost']!, _costMeta),
      );
    }
    if (data.containsKey('performed_at')) {
      context.handle(
        _performedAtMeta,
        performedAt.isAcceptableOrUnknown(
          data['performed_at']!,
          _performedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performedAtMeta);
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
        _nextDueAtMeta,
        nextDueAt.isAcceptableOrUnknown(data['next_due_at']!, _nextDueAtMeta),
      );
    }
    if (data.containsKey('serviced_by')) {
      context.handle(
        _servicedByMeta,
        servicedBy.isAcceptableOrUnknown(data['serviced_by']!, _servicedByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaintenanceLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaintenanceLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      ),
      propertyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}property_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      cost: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost'],
      ),
      performedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}performed_at'],
      )!,
      nextDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_at'],
      ),
      servicedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serviced_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $MaintenanceLogsTable createAlias(String alias) {
    return $MaintenanceLogsTable(attachedDatabase, alias);
  }
}

class MaintenanceLog extends DataClass implements Insertable<MaintenanceLog> {
  final String id;
  final String? itemId;
  final String? propertyId;
  final String title;
  final String? description;
  final double? cost;
  final DateTime performedAt;
  final DateTime? nextDueAt;
  final String? servicedBy;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const MaintenanceLog({
    required this.id,
    this.itemId,
    this.propertyId,
    required this.title,
    this.description,
    this.cost,
    required this.performedAt,
    this.nextDueAt,
    this.servicedBy,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    if (!nullToAbsent || propertyId != null) {
      map['property_id'] = Variable<String>(propertyId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || cost != null) {
      map['cost'] = Variable<double>(cost);
    }
    map['performed_at'] = Variable<DateTime>(performedAt);
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt);
    }
    if (!nullToAbsent || servicedBy != null) {
      map['serviced_by'] = Variable<String>(servicedBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  MaintenanceLogsCompanion toCompanion(bool nullToAbsent) {
    return MaintenanceLogsCompanion(
      id: Value(id),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      propertyId: propertyId == null && nullToAbsent
          ? const Value.absent()
          : Value(propertyId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      cost: cost == null && nullToAbsent ? const Value.absent() : Value(cost),
      performedAt: Value(performedAt),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
      servicedBy: servicedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(servicedBy),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory MaintenanceLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaintenanceLog(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      propertyId: serializer.fromJson<String?>(json['propertyId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      cost: serializer.fromJson<double?>(json['cost']),
      performedAt: serializer.fromJson<DateTime>(json['performedAt']),
      nextDueAt: serializer.fromJson<DateTime?>(json['nextDueAt']),
      servicedBy: serializer.fromJson<String?>(json['servicedBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String?>(itemId),
      'propertyId': serializer.toJson<String?>(propertyId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'cost': serializer.toJson<double?>(cost),
      'performedAt': serializer.toJson<DateTime>(performedAt),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
      'servicedBy': serializer.toJson<String?>(servicedBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  MaintenanceLog copyWith({
    String? id,
    Value<String?> itemId = const Value.absent(),
    Value<String?> propertyId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    Value<double?> cost = const Value.absent(),
    DateTime? performedAt,
    Value<DateTime?> nextDueAt = const Value.absent(),
    Value<String?> servicedBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => MaintenanceLog(
    id: id ?? this.id,
    itemId: itemId.present ? itemId.value : this.itemId,
    propertyId: propertyId.present ? propertyId.value : this.propertyId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    cost: cost.present ? cost.value : this.cost,
    performedAt: performedAt ?? this.performedAt,
    nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
    servicedBy: servicedBy.present ? servicedBy.value : this.servicedBy,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  MaintenanceLog copyWithCompanion(MaintenanceLogsCompanion data) {
    return MaintenanceLog(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      propertyId: data.propertyId.present
          ? data.propertyId.value
          : this.propertyId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      cost: data.cost.present ? data.cost.value : this.cost,
      performedAt: data.performedAt.present
          ? data.performedAt.value
          : this.performedAt,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
      servicedBy: data.servicedBy.present
          ? data.servicedBy.value
          : this.servicedBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceLog(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('propertyId: $propertyId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('cost: $cost, ')
          ..write('performedAt: $performedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('servicedBy: $servicedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    propertyId,
    title,
    description,
    cost,
    performedAt,
    nextDueAt,
    servicedBy,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaintenanceLog &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.propertyId == this.propertyId &&
          other.title == this.title &&
          other.description == this.description &&
          other.cost == this.cost &&
          other.performedAt == this.performedAt &&
          other.nextDueAt == this.nextDueAt &&
          other.servicedBy == this.servicedBy &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class MaintenanceLogsCompanion extends UpdateCompanion<MaintenanceLog> {
  final Value<String> id;
  final Value<String?> itemId;
  final Value<String?> propertyId;
  final Value<String> title;
  final Value<String?> description;
  final Value<double?> cost;
  final Value<DateTime> performedAt;
  final Value<DateTime?> nextDueAt;
  final Value<String?> servicedBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const MaintenanceLogsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.propertyId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.cost = const Value.absent(),
    this.performedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.servicedBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MaintenanceLogsCompanion.insert({
    required String id,
    this.itemId = const Value.absent(),
    this.propertyId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.cost = const Value.absent(),
    required DateTime performedAt,
    this.nextDueAt = const Value.absent(),
    this.servicedBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       performedAt = Value(performedAt),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<MaintenanceLog> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? propertyId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<double>? cost,
    Expression<DateTime>? performedAt,
    Expression<DateTime>? nextDueAt,
    Expression<String>? servicedBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (propertyId != null) 'property_id': propertyId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (cost != null) 'cost': cost,
      if (performedAt != null) 'performed_at': performedAt,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (servicedBy != null) 'serviced_by': servicedBy,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MaintenanceLogsCompanion copyWith({
    Value<String>? id,
    Value<String?>? itemId,
    Value<String?>? propertyId,
    Value<String>? title,
    Value<String?>? description,
    Value<double?>? cost,
    Value<DateTime>? performedAt,
    Value<DateTime?>? nextDueAt,
    Value<String?>? servicedBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return MaintenanceLogsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      propertyId: propertyId ?? this.propertyId,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      performedAt: performedAt ?? this.performedAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      servicedBy: servicedBy ?? this.servicedBy,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (propertyId.present) {
      map['property_id'] = Variable<String>(propertyId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (performedAt.present) {
      map['performed_at'] = Variable<DateTime>(performedAt.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt.value);
    }
    if (servicedBy.present) {
      map['serviced_by'] = Variable<String>(servicedBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaintenanceLogsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('propertyId: $propertyId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('cost: $cost, ')
          ..write('performedAt: $performedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('servicedBy: $servicedBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VideoAnalysesTable extends VideoAnalyses
    with TableInfo<$VideoAnalysesTable, VideoAnalyse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VideoAnalysesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoPathMeta = const VerificationMeta(
    'videoPath',
  );
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
    'video_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerTierMeta = const VerificationMeta(
    'providerTier',
  );
  @override
  late final GeneratedColumn<String> providerTier = GeneratedColumn<String>(
    'provider_tier',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frameCountMeta = const VerificationMeta(
    'frameCount',
  );
  @override
  late final GeneratedColumn<int> frameCount = GeneratedColumn<int>(
    'frame_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _itemsDetectedMeta = const VerificationMeta(
    'itemsDetected',
  );
  @override
  late final GeneratedColumn<int> itemsDetected = GeneratedColumn<int>(
    'items_detected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoPath,
    roomId,
    status,
    providerTier,
    frameCount,
    itemsDetected,
    startedAt,
    completedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'video_analyses';
  @override
  VerificationContext validateIntegrity(
    Insertable<VideoAnalyse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('video_path')) {
      context.handle(
        _videoPathMeta,
        videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta),
      );
    } else if (isInserting) {
      context.missing(_videoPathMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('provider_tier')) {
      context.handle(
        _providerTierMeta,
        providerTier.isAcceptableOrUnknown(
          data['provider_tier']!,
          _providerTierMeta,
        ),
      );
    }
    if (data.containsKey('frame_count')) {
      context.handle(
        _frameCountMeta,
        frameCount.isAcceptableOrUnknown(data['frame_count']!, _frameCountMeta),
      );
    }
    if (data.containsKey('items_detected')) {
      context.handle(
        _itemsDetectedMeta,
        itemsDetected.isAcceptableOrUnknown(
          data['items_detected']!,
          _itemsDetectedMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VideoAnalyse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VideoAnalyse(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      videoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_path'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      providerTier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_tier'],
      ),
      frameCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}frame_count'],
      )!,
      itemsDetected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}items_detected'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $VideoAnalysesTable createAlias(String alias) {
    return $VideoAnalysesTable(attachedDatabase, alias);
  }
}

class VideoAnalyse extends DataClass implements Insertable<VideoAnalyse> {
  final String id;
  final String videoPath;
  final String? roomId;
  final String status;
  final String? providerTier;
  final int frameCount;
  final int itemsDetected;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const VideoAnalyse({
    required this.id,
    required this.videoPath,
    this.roomId,
    required this.status,
    this.providerTier,
    required this.frameCount,
    required this.itemsDetected,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['video_path'] = Variable<String>(videoPath);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<String>(roomId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || providerTier != null) {
      map['provider_tier'] = Variable<String>(providerTier);
    }
    map['frame_count'] = Variable<int>(frameCount);
    map['items_detected'] = Variable<int>(itemsDetected);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  VideoAnalysesCompanion toCompanion(bool nullToAbsent) {
    return VideoAnalysesCompanion(
      id: Value(id),
      videoPath: Value(videoPath),
      roomId: roomId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomId),
      status: Value(status),
      providerTier: providerTier == null && nullToAbsent
          ? const Value.absent()
          : Value(providerTier),
      frameCount: Value(frameCount),
      itemsDetected: Value(itemsDetected),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory VideoAnalyse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VideoAnalyse(
      id: serializer.fromJson<String>(json['id']),
      videoPath: serializer.fromJson<String>(json['videoPath']),
      roomId: serializer.fromJson<String?>(json['roomId']),
      status: serializer.fromJson<String>(json['status']),
      providerTier: serializer.fromJson<String?>(json['providerTier']),
      frameCount: serializer.fromJson<int>(json['frameCount']),
      itemsDetected: serializer.fromJson<int>(json['itemsDetected']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'videoPath': serializer.toJson<String>(videoPath),
      'roomId': serializer.toJson<String?>(roomId),
      'status': serializer.toJson<String>(status),
      'providerTier': serializer.toJson<String?>(providerTier),
      'frameCount': serializer.toJson<int>(frameCount),
      'itemsDetected': serializer.toJson<int>(itemsDetected),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  VideoAnalyse copyWith({
    String? id,
    String? videoPath,
    Value<String?> roomId = const Value.absent(),
    String? status,
    Value<String?> providerTier = const Value.absent(),
    int? frameCount,
    int? itemsDetected,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => VideoAnalyse(
    id: id ?? this.id,
    videoPath: videoPath ?? this.videoPath,
    roomId: roomId.present ? roomId.value : this.roomId,
    status: status ?? this.status,
    providerTier: providerTier.present ? providerTier.value : this.providerTier,
    frameCount: frameCount ?? this.frameCount,
    itemsDetected: itemsDetected ?? this.itemsDetected,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  VideoAnalyse copyWithCompanion(VideoAnalysesCompanion data) {
    return VideoAnalyse(
      id: data.id.present ? data.id.value : this.id,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      status: data.status.present ? data.status.value : this.status,
      providerTier: data.providerTier.present
          ? data.providerTier.value
          : this.providerTier,
      frameCount: data.frameCount.present
          ? data.frameCount.value
          : this.frameCount,
      itemsDetected: data.itemsDetected.present
          ? data.itemsDetected.value
          : this.itemsDetected,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VideoAnalyse(')
          ..write('id: $id, ')
          ..write('videoPath: $videoPath, ')
          ..write('roomId: $roomId, ')
          ..write('status: $status, ')
          ..write('providerTier: $providerTier, ')
          ..write('frameCount: $frameCount, ')
          ..write('itemsDetected: $itemsDetected, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoPath,
    roomId,
    status,
    providerTier,
    frameCount,
    itemsDetected,
    startedAt,
    completedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VideoAnalyse &&
          other.id == this.id &&
          other.videoPath == this.videoPath &&
          other.roomId == this.roomId &&
          other.status == this.status &&
          other.providerTier == this.providerTier &&
          other.frameCount == this.frameCount &&
          other.itemsDetected == this.itemsDetected &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class VideoAnalysesCompanion extends UpdateCompanion<VideoAnalyse> {
  final Value<String> id;
  final Value<String> videoPath;
  final Value<String?> roomId;
  final Value<String> status;
  final Value<String?> providerTier;
  final Value<int> frameCount;
  final Value<int> itemsDetected;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const VideoAnalysesCompanion({
    this.id = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.roomId = const Value.absent(),
    this.status = const Value.absent(),
    this.providerTier = const Value.absent(),
    this.frameCount = const Value.absent(),
    this.itemsDetected = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VideoAnalysesCompanion.insert({
    required String id,
    required String videoPath,
    this.roomId = const Value.absent(),
    required String status,
    this.providerTier = const Value.absent(),
    this.frameCount = const Value.absent(),
    this.itemsDetected = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       videoPath = Value(videoPath),
       status = Value(status),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<VideoAnalyse> custom({
    Expression<String>? id,
    Expression<String>? videoPath,
    Expression<String>? roomId,
    Expression<String>? status,
    Expression<String>? providerTier,
    Expression<int>? frameCount,
    Expression<int>? itemsDetected,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoPath != null) 'video_path': videoPath,
      if (roomId != null) 'room_id': roomId,
      if (status != null) 'status': status,
      if (providerTier != null) 'provider_tier': providerTier,
      if (frameCount != null) 'frame_count': frameCount,
      if (itemsDetected != null) 'items_detected': itemsDetected,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VideoAnalysesCompanion copyWith({
    Value<String>? id,
    Value<String>? videoPath,
    Value<String?>? roomId,
    Value<String>? status,
    Value<String?>? providerTier,
    Value<int>? frameCount,
    Value<int>? itemsDetected,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return VideoAnalysesCompanion(
      id: id ?? this.id,
      videoPath: videoPath ?? this.videoPath,
      roomId: roomId ?? this.roomId,
      status: status ?? this.status,
      providerTier: providerTier ?? this.providerTier,
      frameCount: frameCount ?? this.frameCount,
      itemsDetected: itemsDetected ?? this.itemsDetected,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (providerTier.present) {
      map['provider_tier'] = Variable<String>(providerTier.value);
    }
    if (frameCount.present) {
      map['frame_count'] = Variable<int>(frameCount.value);
    }
    if (itemsDetected.present) {
      map['items_detected'] = Variable<int>(itemsDetected.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VideoAnalysesCompanion(')
          ..write('id: $id, ')
          ..write('videoPath: $videoPath, ')
          ..write('roomId: $roomId, ')
          ..write('status: $status, ')
          ..write('providerTier: $providerTier, ')
          ..write('frameCount: $frameCount, ')
          ..write('itemsDetected: $itemsDetected, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductLookupCacheTable extends ProductLookupCache
    with TableInfo<$ProductLookupCacheTable, ProductLookupCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductLookupCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    barcode,
    name,
    description,
    brand,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_lookup_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductLookupCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    } else if (isInserting) {
      context.missing(_barcodeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {barcode};
  @override
  ProductLookupCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductLookupCacheData(
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ProductLookupCacheTable createAlias(String alias) {
    return $ProductLookupCacheTable(attachedDatabase, alias);
  }
}

class ProductLookupCacheData extends DataClass
    implements Insertable<ProductLookupCacheData> {
  final String barcode;
  final String name;
  final String? description;
  final String? brand;
  final DateTime cachedAt;
  const ProductLookupCacheData({
    required this.barcode,
    required this.name,
    this.description,
    this.brand,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['barcode'] = Variable<String>(barcode);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ProductLookupCacheCompanion toCompanion(bool nullToAbsent) {
    return ProductLookupCacheCompanion(
      barcode: Value(barcode),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      cachedAt: Value(cachedAt),
    );
  }

  factory ProductLookupCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductLookupCacheData(
      barcode: serializer.fromJson<String>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      brand: serializer.fromJson<String?>(json['brand']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'barcode': serializer.toJson<String>(barcode),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'brand': serializer.toJson<String?>(brand),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ProductLookupCacheData copyWith({
    String? barcode,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    DateTime? cachedAt,
  }) => ProductLookupCacheData(
    barcode: barcode ?? this.barcode,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    brand: brand.present ? brand.value : this.brand,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ProductLookupCacheData copyWithCompanion(ProductLookupCacheCompanion data) {
    return ProductLookupCacheData(
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      brand: data.brand.present ? data.brand.value : this.brand,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductLookupCacheData(')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(barcode, name, description, brand, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductLookupCacheData &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.description == this.description &&
          other.brand == this.brand &&
          other.cachedAt == this.cachedAt);
}

class ProductLookupCacheCompanion
    extends UpdateCompanion<ProductLookupCacheData> {
  final Value<String> barcode;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> brand;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const ProductLookupCacheCompanion({
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductLookupCacheCompanion.insert({
    required String barcode,
    required String name,
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  }) : barcode = Value(barcode),
       name = Value(name),
       cachedAt = Value(cachedAt);
  static Insertable<ProductLookupCacheData> custom({
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? brand,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (brand != null) 'brand': brand,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductLookupCacheCompanion copyWith({
    Value<String>? barcode,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? brand,
    Value<DateTime>? cachedAt,
    Value<int>? rowid,
  }) {
    return ProductLookupCacheCompanion(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductLookupCacheCompanion(')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LoansTable extends Loans with TableInfo<$LoansTable, Loan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LoansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _borrowerNameMeta = const VerificationMeta(
    'borrowerName',
  );
  @override
  late final GeneratedColumn<String> borrowerName = GeneratedColumn<String>(
    'borrower_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedReturnDateMeta =
      const VerificationMeta('expectedReturnDate');
  @override
  late final GeneratedColumn<DateTime> expectedReturnDate =
      GeneratedColumn<DateTime>(
        'expected_return_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _returnedAtMeta = const VerificationMeta(
    'returnedAt',
  );
  @override
  late final GeneratedColumn<DateTime> returnedAt = GeneratedColumn<DateTime>(
    'returned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    borrowerName,
    expectedReturnDate,
    notes,
    returnedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'loans';
  @override
  VerificationContext validateIntegrity(
    Insertable<Loan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('borrower_name')) {
      context.handle(
        _borrowerNameMeta,
        borrowerName.isAcceptableOrUnknown(
          data['borrower_name']!,
          _borrowerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_borrowerNameMeta);
    }
    if (data.containsKey('expected_return_date')) {
      context.handle(
        _expectedReturnDateMeta,
        expectedReturnDate.isAcceptableOrUnknown(
          data['expected_return_date']!,
          _expectedReturnDateMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('returned_at')) {
      context.handle(
        _returnedAtMeta,
        returnedAt.isAcceptableOrUnknown(data['returned_at']!, _returnedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Loan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Loan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      borrowerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}borrower_name'],
      )!,
      expectedReturnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_return_date'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      returnedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}returned_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $LoansTable createAlias(String alias) {
    return $LoansTable(attachedDatabase, alias);
  }
}

class Loan extends DataClass implements Insertable<Loan> {
  final String id;
  final String itemId;
  final String borrowerName;
  final DateTime? expectedReturnDate;
  final String? notes;
  final DateTime? returnedAt;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Loan({
    required this.id,
    required this.itemId,
    required this.borrowerName,
    this.expectedReturnDate,
    this.notes,
    this.returnedAt,
    required this.createdAt,
    required this.modifiedAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['borrower_name'] = Variable<String>(borrowerName);
    if (!nullToAbsent || expectedReturnDate != null) {
      map['expected_return_date'] = Variable<DateTime>(expectedReturnDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || returnedAt != null) {
      map['returned_at'] = Variable<DateTime>(returnedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  LoansCompanion toCompanion(bool nullToAbsent) {
    return LoansCompanion(
      id: Value(id),
      itemId: Value(itemId),
      borrowerName: Value(borrowerName),
      expectedReturnDate: expectedReturnDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedReturnDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      returnedAt: returnedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(returnedAt),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Loan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Loan(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      borrowerName: serializer.fromJson<String>(json['borrowerName']),
      expectedReturnDate: serializer.fromJson<DateTime?>(
        json['expectedReturnDate'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      returnedAt: serializer.fromJson<DateTime?>(json['returnedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'borrowerName': serializer.toJson<String>(borrowerName),
      'expectedReturnDate': serializer.toJson<DateTime?>(expectedReturnDate),
      'notes': serializer.toJson<String?>(notes),
      'returnedAt': serializer.toJson<DateTime?>(returnedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Loan copyWith({
    String? id,
    String? itemId,
    String? borrowerName,
    Value<DateTime?> expectedReturnDate = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> returnedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Loan(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    borrowerName: borrowerName ?? this.borrowerName,
    expectedReturnDate: expectedReturnDate.present
        ? expectedReturnDate.value
        : this.expectedReturnDate,
    notes: notes.present ? notes.value : this.notes,
    returnedAt: returnedAt.present ? returnedAt.value : this.returnedAt,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Loan copyWithCompanion(LoansCompanion data) {
    return Loan(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      borrowerName: data.borrowerName.present
          ? data.borrowerName.value
          : this.borrowerName,
      expectedReturnDate: data.expectedReturnDate.present
          ? data.expectedReturnDate.value
          : this.expectedReturnDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      returnedAt: data.returnedAt.present
          ? data.returnedAt.value
          : this.returnedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Loan(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('expectedReturnDate: $expectedReturnDate, ')
          ..write('notes: $notes, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    borrowerName,
    expectedReturnDate,
    notes,
    returnedAt,
    createdAt,
    modifiedAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Loan &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.borrowerName == this.borrowerName &&
          other.expectedReturnDate == this.expectedReturnDate &&
          other.notes == this.notes &&
          other.returnedAt == this.returnedAt &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class LoansCompanion extends UpdateCompanion<Loan> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> borrowerName;
  final Value<DateTime?> expectedReturnDate;
  final Value<String?> notes;
  final Value<DateTime?> returnedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const LoansCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.borrowerName = const Value.absent(),
    this.expectedReturnDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.returnedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LoansCompanion.insert({
    required String id,
    required String itemId,
    required String borrowerName,
    this.expectedReturnDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.returnedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       borrowerName = Value(borrowerName),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Loan> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? borrowerName,
    Expression<DateTime>? expectedReturnDate,
    Expression<String>? notes,
    Expression<DateTime>? returnedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (borrowerName != null) 'borrower_name': borrowerName,
      if (expectedReturnDate != null)
        'expected_return_date': expectedReturnDate,
      if (notes != null) 'notes': notes,
      if (returnedAt != null) 'returned_at': returnedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LoansCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? borrowerName,
    Value<DateTime?>? expectedReturnDate,
    Value<String?>? notes,
    Value<DateTime?>? returnedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return LoansCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      borrowerName: borrowerName ?? this.borrowerName,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      notes: notes ?? this.notes,
      returnedAt: returnedAt ?? this.returnedAt,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (borrowerName.present) {
      map['borrower_name'] = Variable<String>(borrowerName.value);
    }
    if (expectedReturnDate.present) {
      map['expected_return_date'] = Variable<DateTime>(
        expectedReturnDate.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (returnedAt.present) {
      map['returned_at'] = Variable<DateTime>(returnedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LoansCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('borrowerName: $borrowerName, ')
          ..write('expectedReturnDate: $expectedReturnDate, ')
          ..write('notes: $notes, ')
          ..write('returnedAt: $returnedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppraisalsTable extends Appraisals
    with TableInfo<$AppraisalsTable, Appraisal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppraisalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('USD'),
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _sourceUrlsMeta = const VerificationMeta(
    'sourceUrls',
  );
  @override
  late final GeneratedColumn<String> sourceUrls = GeneratedColumn<String>(
    'source_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _itemModelKeyMeta = const VerificationMeta(
    'itemModelKey',
  );
  @override
  late final GeneratedColumn<String> itemModelKey = GeneratedColumn<String>(
    'item_model_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('US'),
  );
  static const VerificationMeta _queriedAtMeta = const VerificationMeta(
    'queriedAt',
  );
  @override
  late final GeneratedColumn<int> queriedAt = GeneratedColumn<int>(
    'queried_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<int> expiresAt = GeneratedColumn<int>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    mode,
    value,
    currency,
    confidence,
    sourceUrls,
    itemModelKey,
    countryCode,
    queriedAt,
    expiresAt,
    nodeId,
    hlc,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'appraisals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Appraisal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('source_urls')) {
      context.handle(
        _sourceUrlsMeta,
        sourceUrls.isAcceptableOrUnknown(data['source_urls']!, _sourceUrlsMeta),
      );
    }
    if (data.containsKey('item_model_key')) {
      context.handle(
        _itemModelKeyMeta,
        itemModelKey.isAcceptableOrUnknown(
          data['item_model_key']!,
          _itemModelKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_itemModelKeyMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('queried_at')) {
      context.handle(
        _queriedAtMeta,
        queriedAt.isAcceptableOrUnknown(data['queried_at']!, _queriedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_queriedAtMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Appraisal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Appraisal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      )!,
      sourceUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_urls'],
      )!,
      itemModelKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_model_key'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      )!,
      queriedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}queried_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expires_at'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AppraisalsTable createAlias(String alias) {
    return $AppraisalsTable(attachedDatabase, alias);
  }
}

class Appraisal extends DataClass implements Insertable<Appraisal> {
  final String id;
  final String itemId;
  final String mode;
  final double value;
  final String currency;
  final double confidence;
  final String sourceUrls;
  final String itemModelKey;
  final String countryCode;
  final int queriedAt;
  final int expiresAt;
  final String nodeId;
  final String hlc;
  final bool isDeleted;
  const Appraisal({
    required this.id,
    required this.itemId,
    required this.mode,
    required this.value,
    required this.currency,
    required this.confidence,
    required this.sourceUrls,
    required this.itemModelKey,
    required this.countryCode,
    required this.queriedAt,
    required this.expiresAt,
    required this.nodeId,
    required this.hlc,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['mode'] = Variable<String>(mode);
    map['value'] = Variable<double>(value);
    map['currency'] = Variable<String>(currency);
    map['confidence'] = Variable<double>(confidence);
    map['source_urls'] = Variable<String>(sourceUrls);
    map['item_model_key'] = Variable<String>(itemModelKey);
    map['country_code'] = Variable<String>(countryCode);
    map['queried_at'] = Variable<int>(queriedAt);
    map['expires_at'] = Variable<int>(expiresAt);
    map['node_id'] = Variable<String>(nodeId);
    map['hlc'] = Variable<String>(hlc);
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AppraisalsCompanion toCompanion(bool nullToAbsent) {
    return AppraisalsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      mode: Value(mode),
      value: Value(value),
      currency: Value(currency),
      confidence: Value(confidence),
      sourceUrls: Value(sourceUrls),
      itemModelKey: Value(itemModelKey),
      countryCode: Value(countryCode),
      queriedAt: Value(queriedAt),
      expiresAt: Value(expiresAt),
      nodeId: Value(nodeId),
      hlc: Value(hlc),
      isDeleted: Value(isDeleted),
    );
  }

  factory Appraisal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Appraisal(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      mode: serializer.fromJson<String>(json['mode']),
      value: serializer.fromJson<double>(json['value']),
      currency: serializer.fromJson<String>(json['currency']),
      confidence: serializer.fromJson<double>(json['confidence']),
      sourceUrls: serializer.fromJson<String>(json['sourceUrls']),
      itemModelKey: serializer.fromJson<String>(json['itemModelKey']),
      countryCode: serializer.fromJson<String>(json['countryCode']),
      queriedAt: serializer.fromJson<int>(json['queriedAt']),
      expiresAt: serializer.fromJson<int>(json['expiresAt']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'mode': serializer.toJson<String>(mode),
      'value': serializer.toJson<double>(value),
      'currency': serializer.toJson<String>(currency),
      'confidence': serializer.toJson<double>(confidence),
      'sourceUrls': serializer.toJson<String>(sourceUrls),
      'itemModelKey': serializer.toJson<String>(itemModelKey),
      'countryCode': serializer.toJson<String>(countryCode),
      'queriedAt': serializer.toJson<int>(queriedAt),
      'expiresAt': serializer.toJson<int>(expiresAt),
      'nodeId': serializer.toJson<String>(nodeId),
      'hlc': serializer.toJson<String>(hlc),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Appraisal copyWith({
    String? id,
    String? itemId,
    String? mode,
    double? value,
    String? currency,
    double? confidence,
    String? sourceUrls,
    String? itemModelKey,
    String? countryCode,
    int? queriedAt,
    int? expiresAt,
    String? nodeId,
    String? hlc,
    bool? isDeleted,
  }) => Appraisal(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    mode: mode ?? this.mode,
    value: value ?? this.value,
    currency: currency ?? this.currency,
    confidence: confidence ?? this.confidence,
    sourceUrls: sourceUrls ?? this.sourceUrls,
    itemModelKey: itemModelKey ?? this.itemModelKey,
    countryCode: countryCode ?? this.countryCode,
    queriedAt: queriedAt ?? this.queriedAt,
    expiresAt: expiresAt ?? this.expiresAt,
    nodeId: nodeId ?? this.nodeId,
    hlc: hlc ?? this.hlc,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Appraisal copyWithCompanion(AppraisalsCompanion data) {
    return Appraisal(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      mode: data.mode.present ? data.mode.value : this.mode,
      value: data.value.present ? data.value.value : this.value,
      currency: data.currency.present ? data.currency.value : this.currency,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      sourceUrls: data.sourceUrls.present
          ? data.sourceUrls.value
          : this.sourceUrls,
      itemModelKey: data.itemModelKey.present
          ? data.itemModelKey.value
          : this.itemModelKey,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      queriedAt: data.queriedAt.present ? data.queriedAt.value : this.queriedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Appraisal(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('mode: $mode, ')
          ..write('value: $value, ')
          ..write('currency: $currency, ')
          ..write('confidence: $confidence, ')
          ..write('sourceUrls: $sourceUrls, ')
          ..write('itemModelKey: $itemModelKey, ')
          ..write('countryCode: $countryCode, ')
          ..write('queriedAt: $queriedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    mode,
    value,
    currency,
    confidence,
    sourceUrls,
    itemModelKey,
    countryCode,
    queriedAt,
    expiresAt,
    nodeId,
    hlc,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Appraisal &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.mode == this.mode &&
          other.value == this.value &&
          other.currency == this.currency &&
          other.confidence == this.confidence &&
          other.sourceUrls == this.sourceUrls &&
          other.itemModelKey == this.itemModelKey &&
          other.countryCode == this.countryCode &&
          other.queriedAt == this.queriedAt &&
          other.expiresAt == this.expiresAt &&
          other.nodeId == this.nodeId &&
          other.hlc == this.hlc &&
          other.isDeleted == this.isDeleted);
}

class AppraisalsCompanion extends UpdateCompanion<Appraisal> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> mode;
  final Value<double> value;
  final Value<String> currency;
  final Value<double> confidence;
  final Value<String> sourceUrls;
  final Value<String> itemModelKey;
  final Value<String> countryCode;
  final Value<int> queriedAt;
  final Value<int> expiresAt;
  final Value<String> nodeId;
  final Value<String> hlc;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AppraisalsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.mode = const Value.absent(),
    this.value = const Value.absent(),
    this.currency = const Value.absent(),
    this.confidence = const Value.absent(),
    this.sourceUrls = const Value.absent(),
    this.itemModelKey = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.queriedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppraisalsCompanion.insert({
    required String id,
    required String itemId,
    required String mode,
    required double value,
    this.currency = const Value.absent(),
    this.confidence = const Value.absent(),
    this.sourceUrls = const Value.absent(),
    required String itemModelKey,
    this.countryCode = const Value.absent(),
    required int queriedAt,
    required int expiresAt,
    this.nodeId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       mode = Value(mode),
       value = Value(value),
       itemModelKey = Value(itemModelKey),
       queriedAt = Value(queriedAt),
       expiresAt = Value(expiresAt);
  static Insertable<Appraisal> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? mode,
    Expression<double>? value,
    Expression<String>? currency,
    Expression<double>? confidence,
    Expression<String>? sourceUrls,
    Expression<String>? itemModelKey,
    Expression<String>? countryCode,
    Expression<int>? queriedAt,
    Expression<int>? expiresAt,
    Expression<String>? nodeId,
    Expression<String>? hlc,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (mode != null) 'mode': mode,
      if (value != null) 'value': value,
      if (currency != null) 'currency': currency,
      if (confidence != null) 'confidence': confidence,
      if (sourceUrls != null) 'source_urls': sourceUrls,
      if (itemModelKey != null) 'item_model_key': itemModelKey,
      if (countryCode != null) 'country_code': countryCode,
      if (queriedAt != null) 'queried_at': queriedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (nodeId != null) 'node_id': nodeId,
      if (hlc != null) 'hlc': hlc,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppraisalsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? mode,
    Value<double>? value,
    Value<String>? currency,
    Value<double>? confidence,
    Value<String>? sourceUrls,
    Value<String>? itemModelKey,
    Value<String>? countryCode,
    Value<int>? queriedAt,
    Value<int>? expiresAt,
    Value<String>? nodeId,
    Value<String>? hlc,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AppraisalsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      mode: mode ?? this.mode,
      value: value ?? this.value,
      currency: currency ?? this.currency,
      confidence: confidence ?? this.confidence,
      sourceUrls: sourceUrls ?? this.sourceUrls,
      itemModelKey: itemModelKey ?? this.itemModelKey,
      countryCode: countryCode ?? this.countryCode,
      queriedAt: queriedAt ?? this.queriedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      nodeId: nodeId ?? this.nodeId,
      hlc: hlc ?? this.hlc,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (sourceUrls.present) {
      map['source_urls'] = Variable<String>(sourceUrls.value);
    }
    if (itemModelKey.present) {
      map['item_model_key'] = Variable<String>(itemModelKey.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (queriedAt.present) {
      map['queried_at'] = Variable<int>(queriedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(expiresAt.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppraisalsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('mode: $mode, ')
          ..write('value: $value, ')
          ..write('currency: $currency, ')
          ..write('confidence: $confidence, ')
          ..write('sourceUrls: $sourceUrls, ')
          ..write('itemModelKey: $itemModelKey, ')
          ..write('countryCode: $countryCode, ')
          ..write('queriedAt: $queriedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('nodeId: $nodeId, ')
          ..write('hlc: $hlc, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PropertiesTable properties = $PropertiesTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $StorageContainersTable storageContainers =
      $StorageContainersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ItemTagsTable itemTags = $ItemTagsTable(this);
  late final $PhotosTable photos = $PhotosTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $PriceHistoryEntriesTable priceHistoryEntries =
      $PriceHistoryEntriesTable(this);
  late final $PoliciesTable policies = $PoliciesTable(this);
  late final $MaintenanceLogsTable maintenanceLogs = $MaintenanceLogsTable(
    this,
  );
  late final $VideoAnalysesTable videoAnalyses = $VideoAnalysesTable(this);
  late final $ProductLookupCacheTable productLookupCache =
      $ProductLookupCacheTable(this);
  late final $LoansTable loans = $LoansTable(this);
  late final $AppraisalsTable appraisals = $AppraisalsTable(this);
  late final ItemDao itemDao = ItemDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final LocationDao locationDao = LocationDao(this as AppDatabase);
  late final TagDao tagDao = TagDao(this as AppDatabase);
  late final PhotoDao photoDao = PhotoDao(this as AppDatabase);
  late final ReceiptDao receiptDao = ReceiptDao(this as AppDatabase);
  late final PriceHistoryDao priceHistoryDao = PriceHistoryDao(
    this as AppDatabase,
  );
  late final PolicyDao policyDao = PolicyDao(this as AppDatabase);
  late final MaintenanceDao maintenanceDao = MaintenanceDao(
    this as AppDatabase,
  );
  late final ContainerDao containerDao = ContainerDao(this as AppDatabase);
  late final LoanDao loanDao = LoanDao(this as AppDatabase);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final AppraisalDao appraisalDao = AppraisalDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    properties,
    rooms,
    storageContainers,
    categories,
    profiles,
    items,
    tags,
    itemTags,
    photos,
    receipts,
    priceHistoryEntries,
    policies,
    maintenanceLogs,
    videoAnalyses,
    productLookupCache,
    loans,
    appraisals,
  ];
}

typedef $$PropertiesTableCreateCompanionBuilder =
    PropertiesCompanion Function({
      required String id,
      required String name,
      Value<String?> address,
      Value<String> type,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$PropertiesTableUpdateCompanionBuilder =
    PropertiesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> address,
      Value<String> type,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$PropertiesTableReferences
    extends BaseReferences<_$AppDatabase, $PropertiesTable, Property> {
  $$PropertiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoomsTable, List<Room>> _roomsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rooms,
    aliasName: $_aliasNameGenerator(db.properties.id, db.rooms.propertyId),
  );

  $$RoomsTableProcessedTableManager get roomsRefs {
    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.propertyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_roomsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PoliciesTable, List<Policy>> _policiesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.policies,
    aliasName: $_aliasNameGenerator(db.properties.id, db.policies.propertyId),
  );

  $$PoliciesTableProcessedTableManager get policiesRefs {
    final manager = $$PoliciesTableTableManager(
      $_db,
      $_db.policies,
    ).filter((f) => f.propertyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_policiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaintenanceLogsTable, List<MaintenanceLog>>
  _maintenanceLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.maintenanceLogs,
    aliasName: $_aliasNameGenerator(
      db.properties.id,
      db.maintenanceLogs.propertyId,
    ),
  );

  $$MaintenanceLogsTableProcessedTableManager get maintenanceLogsRefs {
    final manager = $$MaintenanceLogsTableTableManager(
      $_db,
      $_db.maintenanceLogs,
    ).filter((f) => f.propertyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _maintenanceLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PropertiesTableFilterComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> roomsRefs(
    Expression<bool> Function($$RoomsTableFilterComposer f) f,
  ) {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> policiesRefs(
    Expression<bool> Function($$PoliciesTableFilterComposer f) f,
  ) {
    final $$PoliciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.policies,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoliciesTableFilterComposer(
            $db: $db,
            $table: $db.policies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> maintenanceLogsRefs(
    Expression<bool> Function($$MaintenanceLogsTableFilterComposer f) f,
  ) {
    final $$MaintenanceLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceLogs,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceLogsTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PropertiesTableOrderingComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PropertiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PropertiesTable> {
  $$PropertiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> roomsRefs<T extends Object>(
    Expression<T> Function($$RoomsTableAnnotationComposer a) f,
  ) {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> policiesRefs<T extends Object>(
    Expression<T> Function($$PoliciesTableAnnotationComposer a) f,
  ) {
    final $$PoliciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.policies,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PoliciesTableAnnotationComposer(
            $db: $db,
            $table: $db.policies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> maintenanceLogsRefs<T extends Object>(
    Expression<T> Function($$MaintenanceLogsTableAnnotationComposer a) f,
  ) {
    final $$MaintenanceLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceLogs,
      getReferencedColumn: (t) => t.propertyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.maintenanceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PropertiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PropertiesTable,
          Property,
          $$PropertiesTableFilterComposer,
          $$PropertiesTableOrderingComposer,
          $$PropertiesTableAnnotationComposer,
          $$PropertiesTableCreateCompanionBuilder,
          $$PropertiesTableUpdateCompanionBuilder,
          (Property, $$PropertiesTableReferences),
          Property,
          PrefetchHooks Function({
            bool roomsRefs,
            bool policiesRefs,
            bool maintenanceLogsRefs,
          })
        > {
  $$PropertiesTableTableManager(_$AppDatabase db, $PropertiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PropertiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PropertiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PropertiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion(
                id: id,
                name: name,
                address: address,
                type: type,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String> type = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PropertiesCompanion.insert(
                id: id,
                name: name,
                address: address,
                type: type,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PropertiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                roomsRefs = false,
                policiesRefs = false,
                maintenanceLogsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (roomsRefs) db.rooms,
                    if (policiesRefs) db.policies,
                    if (maintenanceLogsRefs) db.maintenanceLogs,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (roomsRefs)
                        await $_getPrefetchedData<
                          Property,
                          $PropertiesTable,
                          Room
                        >(
                          currentTable: table,
                          referencedTable: $$PropertiesTableReferences
                              ._roomsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PropertiesTableReferences(
                                db,
                                table,
                                p0,
                              ).roomsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.propertyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (policiesRefs)
                        await $_getPrefetchedData<
                          Property,
                          $PropertiesTable,
                          Policy
                        >(
                          currentTable: table,
                          referencedTable: $$PropertiesTableReferences
                              ._policiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PropertiesTableReferences(
                                db,
                                table,
                                p0,
                              ).policiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.propertyId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (maintenanceLogsRefs)
                        await $_getPrefetchedData<
                          Property,
                          $PropertiesTable,
                          MaintenanceLog
                        >(
                          currentTable: table,
                          referencedTable: $$PropertiesTableReferences
                              ._maintenanceLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PropertiesTableReferences(
                                db,
                                table,
                                p0,
                              ).maintenanceLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.propertyId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PropertiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PropertiesTable,
      Property,
      $$PropertiesTableFilterComposer,
      $$PropertiesTableOrderingComposer,
      $$PropertiesTableAnnotationComposer,
      $$PropertiesTableCreateCompanionBuilder,
      $$PropertiesTableUpdateCompanionBuilder,
      (Property, $$PropertiesTableReferences),
      Property,
      PrefetchHooks Function({
        bool roomsRefs,
        bool policiesRefs,
        bool maintenanceLogsRefs,
      })
    >;
typedef $$RoomsTableCreateCompanionBuilder =
    RoomsCompanion Function({
      required String id,
      required String propertyId,
      Value<String?> parentId,
      required String name,
      Value<String?> floor,
      Value<int> sortOrder,
      Value<String?> photoPath,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$RoomsTableUpdateCompanionBuilder =
    RoomsCompanion Function({
      Value<String> id,
      Value<String> propertyId,
      Value<String?> parentId,
      Value<String> name,
      Value<String?> floor,
      Value<int> sortOrder,
      Value<String?> photoPath,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$RoomsTableReferences
    extends BaseReferences<_$AppDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PropertiesTable _propertyIdTable(_$AppDatabase db) => db.properties
      .createAlias($_aliasNameGenerator(db.rooms.propertyId, db.properties.id));

  $$PropertiesTableProcessedTableManager get propertyId {
    final $_column = $_itemColumn<String>('property_id')!;

    final manager = $$PropertiesTableTableManager(
      $_db,
      $_db.properties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_propertyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StorageContainersTable, List<StorageContainer>>
  _storageContainersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.storageContainers,
        aliasName: $_aliasNameGenerator(
          db.rooms.id,
          db.storageContainers.roomId,
        ),
      );

  $$StorageContainersTableProcessedTableManager get storageContainersRefs {
    final manager = $$StorageContainersTableTableManager(
      $_db,
      $_db.storageContainers,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _storageContainersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.rooms.id, db.items.roomId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.roomId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoomsTableFilterComposer extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get floor => $composableBuilder(
    column: $table.floor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$PropertiesTableFilterComposer get propertyId {
    final $$PropertiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableFilterComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storageContainersRefs(
    Expression<bool> Function($$StorageContainersTableFilterComposer f) f,
  ) {
    final $$StorageContainersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storageContainers,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StorageContainersTableFilterComposer(
            $db: $db,
            $table: $db.storageContainers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get floor => $composableBuilder(
    column: $table.floor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$PropertiesTableOrderingComposer get propertyId {
    final $$PropertiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableOrderingComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get floor =>
      $composableBuilder(column: $table.floor, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$PropertiesTableAnnotationComposer get propertyId {
    final $$PropertiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableAnnotationComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storageContainersRefs<T extends Object>(
    Expression<T> Function($$StorageContainersTableAnnotationComposer a) f,
  ) {
    final $$StorageContainersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.storageContainers,
          getReferencedColumn: (t) => t.roomId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StorageContainersTableAnnotationComposer(
                $db: $db,
                $table: $db.storageContainers,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.roomId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoomsTable,
          Room,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (Room, $$RoomsTableReferences),
          Room,
          PrefetchHooks Function({
            bool propertyId,
            bool storageContainersRefs,
            bool itemsRefs,
          })
        > {
  $$RoomsTableTableManager(_$AppDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> propertyId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> floor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion(
                id: id,
                propertyId: propertyId,
                parentId: parentId,
                name: name,
                floor: floor,
                sortOrder: sortOrder,
                photoPath: photoPath,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String propertyId,
                Value<String?> parentId = const Value.absent(),
                required String name,
                Value<String?> floor = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion.insert(
                id: id,
                propertyId: propertyId,
                parentId: parentId,
                name: name,
                floor: floor,
                sortOrder: sortOrder,
                photoPath: photoPath,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoomsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                propertyId = false,
                storageContainersRefs = false,
                itemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storageContainersRefs) db.storageContainers,
                    if (itemsRefs) db.items,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (propertyId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.propertyId,
                                    referencedTable: $$RoomsTableReferences
                                        ._propertyIdTable(db),
                                    referencedColumn: $$RoomsTableReferences
                                        ._propertyIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storageContainersRefs)
                        await $_getPrefetchedData<
                          Room,
                          $RoomsTable,
                          StorageContainer
                        >(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._storageContainersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(
                                db,
                                table,
                                p0,
                              ).storageContainersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (itemsRefs)
                        await $_getPrefetchedData<Room, $RoomsTable, Item>(
                          currentTable: table,
                          referencedTable: $$RoomsTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$RoomsTableReferences(db, table, p0).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.roomId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoomsTable,
      Room,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (Room, $$RoomsTableReferences),
      Room,
      PrefetchHooks Function({
        bool propertyId,
        bool storageContainersRefs,
        bool itemsRefs,
      })
    >;
typedef $$StorageContainersTableCreateCompanionBuilder =
    StorageContainersCompanion Function({
      required String id,
      required String roomId,
      required String name,
      Value<String?> type,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$StorageContainersTableUpdateCompanionBuilder =
    StorageContainersCompanion Function({
      Value<String> id,
      Value<String> roomId,
      Value<String> name,
      Value<String?> type,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$StorageContainersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StorageContainersTable,
          StorageContainer
        > {
  $$StorageContainersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RoomsTable _roomIdTable(_$AppDatabase db) => db.rooms.createAlias(
    $_aliasNameGenerator(db.storageContainers.roomId, db.rooms.id),
  );

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StorageContainersTableFilterComposer
    extends Composer<_$AppDatabase, $StorageContainersTable> {
  $$StorageContainersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StorageContainersTableOrderingComposer
    extends Composer<_$AppDatabase, $StorageContainersTable> {
  $$StorageContainersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StorageContainersTableAnnotationComposer
    extends Composer<_$AppDatabase, $StorageContainersTable> {
  $$StorageContainersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StorageContainersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageContainersTable,
          StorageContainer,
          $$StorageContainersTableFilterComposer,
          $$StorageContainersTableOrderingComposer,
          $$StorageContainersTableAnnotationComposer,
          $$StorageContainersTableCreateCompanionBuilder,
          $$StorageContainersTableUpdateCompanionBuilder,
          (StorageContainer, $$StorageContainersTableReferences),
          StorageContainer,
          PrefetchHooks Function({bool roomId})
        > {
  $$StorageContainersTableTableManager(
    _$AppDatabase db,
    $StorageContainersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageContainersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageContainersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageContainersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageContainersCompanion(
                id: id,
                roomId: roomId,
                name: name,
                type: type,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomId,
                required String name,
                Value<String?> type = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageContainersCompanion.insert(
                id: id,
                roomId: roomId,
                name: name,
                type: type,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StorageContainersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roomId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (roomId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roomId,
                                referencedTable:
                                    $$StorageContainersTableReferences
                                        ._roomIdTable(db),
                                referencedColumn:
                                    $$StorageContainersTableReferences
                                        ._roomIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StorageContainersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageContainersTable,
      StorageContainer,
      $$StorageContainersTableFilterComposer,
      $$StorageContainersTableOrderingComposer,
      $$StorageContainersTableAnnotationComposer,
      $$StorageContainersTableCreateCompanionBuilder,
      $$StorageContainersTableUpdateCompanionBuilder,
      (StorageContainer, $$StorageContainersTableReferences),
      StorageContainer,
      PrefetchHooks Function({bool roomId})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> parentId,
      Value<int?> iconCodePoint,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<int?> iconCodePoint,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: $_aliasNameGenerator(db.categories.id, db.items.categoryId),
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get iconCodePoint => $composableBuilder(
    column: $table.iconCodePoint,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool itemsRefs})
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<int?> iconCodePoint = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                iconCodePoint: iconCodePoint,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<int?> iconCodePoint = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                iconCodePoint: iconCodePoint,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemsRefs) db.items],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemsRefs)
                    await $_getPrefetchedData<Category, $CategoriesTable, Item>(
                      currentTable: table,
                      referencedTable: $$CategoriesTableReferences
                          ._itemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CategoriesTableReferences(db, table, p0).itemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool itemsRefs})
    >;
typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      required String id,
      required String name,
      Value<String> colorHex,
      Value<String> avatarEmoji,
      Value<bool> isDefault,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> colorHex,
      Value<String> avatarEmoji,
      Value<bool> isDefault,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                colorHex: colorHex,
                avatarEmoji: avatarEmoji,
                isDefault: isDefault,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> colorHex = const Value.absent(),
                Value<String> avatarEmoji = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                colorHex: colorHex,
                avatarEmoji: avatarEmoji,
                isDefault: isDefault,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;
typedef $$ItemsTableCreateCompanionBuilder =
    ItemsCompanion Function({
      required String id,
      required String name,
      Value<String> description,
      required String categoryId,
      required String roomId,
      Value<DateTime?> purchaseDate,
      Value<double?> purchasePrice,
      Value<double?> currentValue,
      Value<double?> replacementCost,
      Value<String?> condition,
      Value<String?> serialNumber,
      Value<DateTime?> warrantyExpiration,
      Value<String?> containerId,
      Value<String?> barcode,
      Value<String?> storeUrl,
      Value<String?> notes,
      Value<bool> isInsured,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<double?> quantity,
      Value<String?> quantityUnit,
      Value<double?> lowStockThreshold,
      Value<String?> creatorProfileId,
      Value<String?> ownerProfileId,
      Value<int> rowid,
    });
typedef $$ItemsTableUpdateCompanionBuilder =
    ItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> description,
      Value<String> categoryId,
      Value<String> roomId,
      Value<DateTime?> purchaseDate,
      Value<double?> purchasePrice,
      Value<double?> currentValue,
      Value<double?> replacementCost,
      Value<String?> condition,
      Value<String?> serialNumber,
      Value<DateTime?> warrantyExpiration,
      Value<String?> containerId,
      Value<String?> barcode,
      Value<String?> storeUrl,
      Value<String?> notes,
      Value<bool> isInsured,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<double?> quantity,
      Value<String?> quantityUnit,
      Value<double?> lowStockThreshold,
      Value<String?> creatorProfileId,
      Value<String?> ownerProfileId,
      Value<int> rowid,
    });

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) => db.categories
      .createAlias($_aliasNameGenerator(db.items.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RoomsTable _roomIdTable(_$AppDatabase db) =>
      db.rooms.createAlias($_aliasNameGenerator(db.items.roomId, db.rooms.id));

  $$RoomsTableProcessedTableManager get roomId {
    final $_column = $_itemColumn<String>('room_id')!;

    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roomIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfilesTable _creatorProfileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias(
        $_aliasNameGenerator(db.items.creatorProfileId, db.profiles.id),
      );

  $$ProfilesTableProcessedTableManager? get creatorProfileId {
    final $_column = $_itemColumn<String>('creator_profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_creatorProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProfilesTable _ownerProfileIdTable(_$AppDatabase db) =>
      db.profiles.createAlias(
        $_aliasNameGenerator(db.items.ownerProfileId, db.profiles.id),
      );

  $$ProfilesTableProcessedTableManager? get ownerProfileId {
    final $_column = $_itemColumn<String>('owner_profile_id');
    if ($_column == null) return null;
    final manager = $$ProfilesTableTableManager(
      $_db,
      $_db.profiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ownerProfileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemTagsTable, List<ItemTag>> _itemTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.itemTags,
    aliasName: $_aliasNameGenerator(db.items.id, db.itemTags.itemId),
  );

  $$ItemTagsTableProcessedTableManager get itemTagsRefs {
    final manager = $$ItemTagsTableTableManager(
      $_db,
      $_db.itemTags,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PhotosTable, List<Photo>> _photosRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.photos,
    aliasName: $_aliasNameGenerator(db.items.id, db.photos.itemId),
  );

  $$PhotosTableProcessedTableManager get photosRefs {
    final manager = $$PhotosTableTableManager(
      $_db,
      $_db.photos,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_photosRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.receipts,
    aliasName: $_aliasNameGenerator(db.items.id, db.receipts.itemId),
  );

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PriceHistoryEntriesTable, List<PriceHistoryEntry>>
  _priceHistoryEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.priceHistoryEntries,
        aliasName: $_aliasNameGenerator(
          db.items.id,
          db.priceHistoryEntries.itemId,
        ),
      );

  $$PriceHistoryEntriesTableProcessedTableManager get priceHistoryEntriesRefs {
    final manager = $$PriceHistoryEntriesTableTableManager(
      $_db,
      $_db.priceHistoryEntries,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _priceHistoryEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MaintenanceLogsTable, List<MaintenanceLog>>
  _maintenanceLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.maintenanceLogs,
    aliasName: $_aliasNameGenerator(db.items.id, db.maintenanceLogs.itemId),
  );

  $$MaintenanceLogsTableProcessedTableManager get maintenanceLogsRefs {
    final manager = $$MaintenanceLogsTableTableManager(
      $_db,
      $_db.maintenanceLogs,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _maintenanceLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LoansTable, List<Loan>> _loansRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.loans,
    aliasName: $_aliasNameGenerator(db.items.id, db.loans.itemId),
  );

  $$LoansTableProcessedTableManager get loansRefs {
    final manager = $$LoansTableTableManager(
      $_db,
      $_db.loans,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_loansRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AppraisalsTable, List<Appraisal>>
  _appraisalsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appraisals,
    aliasName: $_aliasNameGenerator(db.items.id, db.appraisals.itemId),
  );

  $$AppraisalsTableProcessedTableManager get appraisalsRefs {
    final manager = $$AppraisalsTableTableManager(
      $_db,
      $_db.appraisals,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appraisalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get replacementCost => $composableBuilder(
    column: $table.replacementCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get warrantyExpiration => $composableBuilder(
    column: $table.warrantyExpiration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeUrl => $composableBuilder(
    column: $table.storeUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isInsured => $composableBuilder(
    column: $table.isInsured,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableFilterComposer get roomId {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableFilterComposer get creatorProfileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableFilterComposer get ownerProfileId {
    final $$ProfilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableFilterComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemTagsRefs(
    Expression<bool> Function($$ItemTagsTableFilterComposer f) f,
  ) {
    final $$ItemTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemTags,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemTagsTableFilterComposer(
            $db: $db,
            $table: $db.itemTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> photosRefs(
    Expression<bool> Function($$PhotosTableFilterComposer f) f,
  ) {
    final $$PhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableFilterComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> receiptsRefs(
    Expression<bool> Function($$ReceiptsTableFilterComposer f) f,
  ) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> priceHistoryEntriesRefs(
    Expression<bool> Function($$PriceHistoryEntriesTableFilterComposer f) f,
  ) {
    final $$PriceHistoryEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistoryEntries,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryEntriesTableFilterComposer(
            $db: $db,
            $table: $db.priceHistoryEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> maintenanceLogsRefs(
    Expression<bool> Function($$MaintenanceLogsTableFilterComposer f) f,
  ) {
    final $$MaintenanceLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceLogsTableFilterComposer(
            $db: $db,
            $table: $db.maintenanceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> loansRefs(
    Expression<bool> Function($$LoansTableFilterComposer f) f,
  ) {
    final $$LoansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableFilterComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> appraisalsRefs(
    Expression<bool> Function($$AppraisalsTableFilterComposer f) f,
  ) {
    final $$AppraisalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appraisals,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppraisalsTableFilterComposer(
            $db: $db,
            $table: $db.appraisals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get replacementCost => $composableBuilder(
    column: $table.replacementCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get warrantyExpiration => $composableBuilder(
    column: $table.warrantyExpiration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeUrl => $composableBuilder(
    column: $table.storeUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isInsured => $composableBuilder(
    column: $table.isInsured,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableOrderingComposer get roomId {
    final $$RoomsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableOrderingComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableOrderingComposer get creatorProfileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableOrderingComposer get ownerProfileId {
    final $$ProfilesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableOrderingComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get replacementCost => $composableBuilder(
    column: $table.replacementCost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get warrantyExpiration => $composableBuilder(
    column: $table.warrantyExpiration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get storeUrl =>
      $composableBuilder(column: $table.storeUrl, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isInsured =>
      $composableBuilder(column: $table.isInsured, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get quantityUnit => $composableBuilder(
    column: $table.quantityUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lowStockThreshold => $composableBuilder(
    column: $table.lowStockThreshold,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RoomsTableAnnotationComposer get roomId {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roomId,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableAnnotationComposer get creatorProfileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.creatorProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProfilesTableAnnotationComposer get ownerProfileId {
    final $$ProfilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ownerProfileId,
      referencedTable: $db.profiles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfilesTableAnnotationComposer(
            $db: $db,
            $table: $db.profiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemTagsRefs<T extends Object>(
    Expression<T> Function($$ItemTagsTableAnnotationComposer a) f,
  ) {
    final $$ItemTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemTags,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> photosRefs<T extends Object>(
    Expression<T> Function($$PhotosTableAnnotationComposer a) f,
  ) {
    final $$PhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.photos,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.photos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> receiptsRefs<T extends Object>(
    Expression<T> Function($$ReceiptsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> priceHistoryEntriesRefs<T extends Object>(
    Expression<T> Function($$PriceHistoryEntriesTableAnnotationComposer a) f,
  ) {
    final $$PriceHistoryEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.priceHistoryEntries,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PriceHistoryEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.priceHistoryEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> maintenanceLogsRefs<T extends Object>(
    Expression<T> Function($$MaintenanceLogsTableAnnotationComposer a) f,
  ) {
    final $$MaintenanceLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.maintenanceLogs,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MaintenanceLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.maintenanceLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> loansRefs<T extends Object>(
    Expression<T> Function($$LoansTableAnnotationComposer a) f,
  ) {
    final $$LoansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.loans,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LoansTableAnnotationComposer(
            $db: $db,
            $table: $db.loans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> appraisalsRefs<T extends Object>(
    Expression<T> Function($$AppraisalsTableAnnotationComposer a) f,
  ) {
    final $$AppraisalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appraisals,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppraisalsTableAnnotationComposer(
            $db: $db,
            $table: $db.appraisals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool categoryId,
            bool roomId,
            bool creatorProfileId,
            bool ownerProfileId,
            bool itemTagsRefs,
            bool photosRefs,
            bool receiptsRefs,
            bool priceHistoryEntriesRefs,
            bool maintenanceLogsRefs,
            bool loansRefs,
            bool appraisalsRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> roomId = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<double?> currentValue = const Value.absent(),
                Value<double?> replacementCost = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<DateTime?> warrantyExpiration = const Value.absent(),
                Value<String?> containerId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> storeUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isInsured = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> quantityUnit = const Value.absent(),
                Value<double?> lowStockThreshold = const Value.absent(),
                Value<String?> creatorProfileId = const Value.absent(),
                Value<String?> ownerProfileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                name: name,
                description: description,
                categoryId: categoryId,
                roomId: roomId,
                purchaseDate: purchaseDate,
                purchasePrice: purchasePrice,
                currentValue: currentValue,
                replacementCost: replacementCost,
                condition: condition,
                serialNumber: serialNumber,
                warrantyExpiration: warrantyExpiration,
                containerId: containerId,
                barcode: barcode,
                storeUrl: storeUrl,
                notes: notes,
                isInsured: isInsured,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                quantity: quantity,
                quantityUnit: quantityUnit,
                lowStockThreshold: lowStockThreshold,
                creatorProfileId: creatorProfileId,
                ownerProfileId: ownerProfileId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> description = const Value.absent(),
                required String categoryId,
                required String roomId,
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<double?> currentValue = const Value.absent(),
                Value<double?> replacementCost = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<DateTime?> warrantyExpiration = const Value.absent(),
                Value<String?> containerId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> storeUrl = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isInsured = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<String?> quantityUnit = const Value.absent(),
                Value<double?> lowStockThreshold = const Value.absent(),
                Value<String?> creatorProfileId = const Value.absent(),
                Value<String?> ownerProfileId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                name: name,
                description: description,
                categoryId: categoryId,
                roomId: roomId,
                purchaseDate: purchaseDate,
                purchasePrice: purchasePrice,
                currentValue: currentValue,
                replacementCost: replacementCost,
                condition: condition,
                serialNumber: serialNumber,
                warrantyExpiration: warrantyExpiration,
                containerId: containerId,
                barcode: barcode,
                storeUrl: storeUrl,
                notes: notes,
                isInsured: isInsured,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                quantity: quantity,
                quantityUnit: quantityUnit,
                lowStockThreshold: lowStockThreshold,
                creatorProfileId: creatorProfileId,
                ownerProfileId: ownerProfileId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ItemsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                roomId = false,
                creatorProfileId = false,
                ownerProfileId = false,
                itemTagsRefs = false,
                photosRefs = false,
                receiptsRefs = false,
                priceHistoryEntriesRefs = false,
                maintenanceLogsRefs = false,
                loansRefs = false,
                appraisalsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemTagsRefs) db.itemTags,
                    if (photosRefs) db.photos,
                    if (receiptsRefs) db.receipts,
                    if (priceHistoryEntriesRefs) db.priceHistoryEntries,
                    if (maintenanceLogsRefs) db.maintenanceLogs,
                    if (loansRefs) db.loans,
                    if (appraisalsRefs) db.appraisals,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: $$ItemsTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (roomId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.roomId,
                                    referencedTable: $$ItemsTableReferences
                                        ._roomIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._roomIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (creatorProfileId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.creatorProfileId,
                                    referencedTable: $$ItemsTableReferences
                                        ._creatorProfileIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._creatorProfileIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (ownerProfileId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ownerProfileId,
                                    referencedTable: $$ItemsTableReferences
                                        ._ownerProfileIdTable(db),
                                    referencedColumn: $$ItemsTableReferences
                                        ._ownerProfileIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemTagsRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, ItemTag>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._itemTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).itemTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (photosRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, Photo>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._photosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(db, table, p0).photosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (receiptsRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, Receipt>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._receiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (priceHistoryEntriesRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          PriceHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._priceHistoryEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceHistoryEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (maintenanceLogsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          MaintenanceLog
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._maintenanceLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).maintenanceLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (loansRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, Loan>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._loansRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(db, table, p0).loansRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (appraisalsRefs)
                        await $_getPrefetchedData<Item, $ItemsTable, Appraisal>(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._appraisalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).appraisalsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool categoryId,
        bool roomId,
        bool creatorProfileId,
        bool ownerProfileId,
        bool itemTagsRefs,
        bool photosRefs,
        bool receiptsRefs,
        bool priceHistoryEntriesRefs,
        bool maintenanceLogsRefs,
        bool loansRefs,
        bool appraisalsRefs,
      })
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      Value<int?> color,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ItemTagsTable, List<ItemTag>> _itemTagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.itemTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.itemTags.tagId),
  );

  $$ItemTagsTableProcessedTableManager get itemTagsRefs {
    final manager = $$ItemTagsTableTableManager(
      $_db,
      $_db.itemTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> itemTagsRefs(
    Expression<bool> Function($$ItemTagsTableFilterComposer f) f,
  ) {
    final $$ItemTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemTagsTableFilterComposer(
            $db: $db,
            $table: $db.itemTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> itemTagsRefs<T extends Object>(
    Expression<T> Function($$ItemTagsTableAnnotationComposer a) f,
  ) {
    final $$ItemTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.itemTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.itemTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool itemTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int?> color = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                color: color,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({itemTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (itemTagsRefs) db.itemTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (itemTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ItemTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._itemTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).itemTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool itemTagsRefs})
    >;
typedef $$ItemTagsTableCreateCompanionBuilder =
    ItemTagsCompanion Function({
      required String itemId,
      required String tagId,
      required DateTime createdAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ItemTagsTableUpdateCompanionBuilder =
    ItemTagsCompanion Function({
      Value<String> itemId,
      Value<String> tagId,
      Value<DateTime> createdAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$ItemTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemTagsTable, ItemTag> {
  $$ItemTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.itemTags.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.itemTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemTagsTable> {
  $$ItemTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemTagsTable,
          ItemTag,
          $$ItemTagsTableFilterComposer,
          $$ItemTagsTableOrderingComposer,
          $$ItemTagsTableAnnotationComposer,
          $$ItemTagsTableCreateCompanionBuilder,
          $$ItemTagsTableUpdateCompanionBuilder,
          (ItemTag, $$ItemTagsTableReferences),
          ItemTag,
          PrefetchHooks Function({bool itemId, bool tagId})
        > {
  $$ItemTagsTableTableManager(_$AppDatabase db, $ItemTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> itemId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemTagsCompanion(
                itemId: itemId,
                tagId: tagId,
                createdAt: createdAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String itemId,
                required String tagId,
                required DateTime createdAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemTagsCompanion.insert(
                itemId: itemId,
                tagId: tagId,
                createdAt: createdAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ItemTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ItemTagsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ItemTagsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$ItemTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$ItemTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ItemTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemTagsTable,
      ItemTag,
      $$ItemTagsTableFilterComposer,
      $$ItemTagsTableOrderingComposer,
      $$ItemTagsTableAnnotationComposer,
      $$ItemTagsTableCreateCompanionBuilder,
      $$ItemTagsTableUpdateCompanionBuilder,
      (ItemTag, $$ItemTagsTableReferences),
      ItemTag,
      PrefetchHooks Function({bool itemId, bool tagId})
    >;
typedef $$PhotosTableCreateCompanionBuilder =
    PhotosCompanion Function({
      required String id,
      required String itemId,
      required String filePath,
      Value<bool> isPrimary,
      Value<String> source,
      required DateTime capturedAt,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$PhotosTableUpdateCompanionBuilder =
    PhotosCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> filePath,
      Value<bool> isPrimary,
      Value<String> source,
      Value<DateTime> capturedAt,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$PhotosTableReferences
    extends BaseReferences<_$AppDatabase, $PhotosTable, Photo> {
  $$PhotosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias($_aliasNameGenerator(db.photos.itemId, db.items.id));

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PhotosTableFilterComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotosTable> {
  $$PhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PhotosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PhotosTable,
          Photo,
          $$PhotosTableFilterComposer,
          $$PhotosTableOrderingComposer,
          $$PhotosTableAnnotationComposer,
          $$PhotosTableCreateCompanionBuilder,
          $$PhotosTableUpdateCompanionBuilder,
          (Photo, $$PhotosTableReferences),
          Photo,
          PrefetchHooks Function({bool itemId})
        > {
  $$PhotosTableTableManager(_$AppDatabase db, $PhotosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion(
                id: id,
                itemId: itemId,
                filePath: filePath,
                isPrimary: isPrimary,
                source: source,
                capturedAt: capturedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String filePath,
                Value<bool> isPrimary = const Value.absent(),
                Value<String> source = const Value.absent(),
                required DateTime capturedAt,
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotosCompanion.insert(
                id: id,
                itemId: itemId,
                filePath: filePath,
                isPrimary: isPrimary,
                source: source,
                capturedAt: capturedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PhotosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$PhotosTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$PhotosTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PhotosTable,
      Photo,
      $$PhotosTableFilterComposer,
      $$PhotosTableOrderingComposer,
      $$PhotosTableAnnotationComposer,
      $$PhotosTableCreateCompanionBuilder,
      $$PhotosTableUpdateCompanionBuilder,
      (Photo, $$PhotosTableReferences),
      Photo,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      required String id,
      Value<String?> itemId,
      required String photoPath,
      Value<String?> storeName,
      Value<DateTime?> purchaseDate,
      Value<double?> totalAmount,
      Value<String?> ocrText,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<String> id,
      Value<String?> itemId,
      Value<String> photoPath,
      Value<String?> storeName,
      Value<DateTime?> purchaseDate,
      Value<double?> totalAmount,
      Value<String?> ocrText,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.receipts.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeName => $composableBuilder(
    column: $table.storeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get storeName =>
      $composableBuilder(column: $table.storeName, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({bool itemId})
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String> photoPath = const Value.absent(),
                Value<String?> storeName = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                itemId: itemId,
                photoPath: photoPath,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                ocrText: ocrText,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> itemId = const Value.absent(),
                required String photoPath,
                Value<String?> storeName = const Value.absent(),
                Value<DateTime?> purchaseDate = const Value.absent(),
                Value<double?> totalAmount = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                id: id,
                itemId: itemId,
                photoPath: photoPath,
                storeName: storeName,
                purchaseDate: purchaseDate,
                totalAmount: totalAmount,
                ocrText: ocrText,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$ReceiptsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$ReceiptsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$PriceHistoryEntriesTableCreateCompanionBuilder =
    PriceHistoryEntriesCompanion Function({
      required String id,
      required String itemId,
      required double price,
      required String source,
      required DateTime recordedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$PriceHistoryEntriesTableUpdateCompanionBuilder =
    PriceHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<double> price,
      Value<String> source,
      Value<DateTime> recordedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$PriceHistoryEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PriceHistoryEntriesTable,
          PriceHistoryEntry
        > {
  $$PriceHistoryEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.priceHistoryEntries.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceHistoryEntriesTable> {
  $$PriceHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceHistoryEntriesTable,
          PriceHistoryEntry,
          $$PriceHistoryEntriesTableFilterComposer,
          $$PriceHistoryEntriesTableOrderingComposer,
          $$PriceHistoryEntriesTableAnnotationComposer,
          $$PriceHistoryEntriesTableCreateCompanionBuilder,
          $$PriceHistoryEntriesTableUpdateCompanionBuilder,
          (PriceHistoryEntry, $$PriceHistoryEntriesTableReferences),
          PriceHistoryEntry,
          PrefetchHooks Function({bool itemId})
        > {
  $$PriceHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $PriceHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceHistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PriceHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryEntriesCompanion(
                id: id,
                itemId: itemId,
                price: price,
                source: source,
                recordedAt: recordedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required double price,
                required String source,
                required DateTime recordedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PriceHistoryEntriesCompanion.insert(
                id: id,
                itemId: itemId,
                price: price,
                source: source,
                recordedAt: recordedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PriceHistoryEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$PriceHistoryEntriesTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$PriceHistoryEntriesTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PriceHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceHistoryEntriesTable,
      PriceHistoryEntry,
      $$PriceHistoryEntriesTableFilterComposer,
      $$PriceHistoryEntriesTableOrderingComposer,
      $$PriceHistoryEntriesTableAnnotationComposer,
      $$PriceHistoryEntriesTableCreateCompanionBuilder,
      $$PriceHistoryEntriesTableUpdateCompanionBuilder,
      (PriceHistoryEntry, $$PriceHistoryEntriesTableReferences),
      PriceHistoryEntry,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$PoliciesTableCreateCompanionBuilder =
    PoliciesCompanion Function({
      required String id,
      required String propertyId,
      required String provider,
      Value<String?> policyNumber,
      Value<double?> coverageAmount,
      Value<double?> deductible,
      Value<double?> premium,
      Value<DateTime?> expiryDate,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$PoliciesTableUpdateCompanionBuilder =
    PoliciesCompanion Function({
      Value<String> id,
      Value<String> propertyId,
      Value<String> provider,
      Value<String?> policyNumber,
      Value<double?> coverageAmount,
      Value<double?> deductible,
      Value<double?> premium,
      Value<DateTime?> expiryDate,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$PoliciesTableReferences
    extends BaseReferences<_$AppDatabase, $PoliciesTable, Policy> {
  $$PoliciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PropertiesTable _propertyIdTable(_$AppDatabase db) =>
      db.properties.createAlias(
        $_aliasNameGenerator(db.policies.propertyId, db.properties.id),
      );

  $$PropertiesTableProcessedTableManager get propertyId {
    final $_column = $_itemColumn<String>('property_id')!;

    final manager = $$PropertiesTableTableManager(
      $_db,
      $_db.properties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_propertyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PoliciesTableFilterComposer
    extends Composer<_$AppDatabase, $PoliciesTable> {
  $$PoliciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get coverageAmount => $composableBuilder(
    column: $table.coverageAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deductible => $composableBuilder(
    column: $table.deductible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get premium => $composableBuilder(
    column: $table.premium,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$PropertiesTableFilterComposer get propertyId {
    final $$PropertiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableFilterComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoliciesTableOrderingComposer
    extends Composer<_$AppDatabase, $PoliciesTable> {
  $$PoliciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get coverageAmount => $composableBuilder(
    column: $table.coverageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deductible => $composableBuilder(
    column: $table.deductible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get premium => $composableBuilder(
    column: $table.premium,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$PropertiesTableOrderingComposer get propertyId {
    final $$PropertiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableOrderingComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoliciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PoliciesTable> {
  $$PoliciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get policyNumber => $composableBuilder(
    column: $table.policyNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get coverageAmount => $composableBuilder(
    column: $table.coverageAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deductible => $composableBuilder(
    column: $table.deductible,
    builder: (column) => column,
  );

  GeneratedColumn<double> get premium =>
      $composableBuilder(column: $table.premium, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$PropertiesTableAnnotationComposer get propertyId {
    final $$PropertiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableAnnotationComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PoliciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PoliciesTable,
          Policy,
          $$PoliciesTableFilterComposer,
          $$PoliciesTableOrderingComposer,
          $$PoliciesTableAnnotationComposer,
          $$PoliciesTableCreateCompanionBuilder,
          $$PoliciesTableUpdateCompanionBuilder,
          (Policy, $$PoliciesTableReferences),
          Policy,
          PrefetchHooks Function({bool propertyId})
        > {
  $$PoliciesTableTableManager(_$AppDatabase db, $PoliciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PoliciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PoliciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PoliciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> propertyId = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String?> policyNumber = const Value.absent(),
                Value<double?> coverageAmount = const Value.absent(),
                Value<double?> deductible = const Value.absent(),
                Value<double?> premium = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoliciesCompanion(
                id: id,
                propertyId: propertyId,
                provider: provider,
                policyNumber: policyNumber,
                coverageAmount: coverageAmount,
                deductible: deductible,
                premium: premium,
                expiryDate: expiryDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String propertyId,
                required String provider,
                Value<String?> policyNumber = const Value.absent(),
                Value<double?> coverageAmount = const Value.absent(),
                Value<double?> deductible = const Value.absent(),
                Value<double?> premium = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoliciesCompanion.insert(
                id: id,
                propertyId: propertyId,
                provider: provider,
                policyNumber: policyNumber,
                coverageAmount: coverageAmount,
                deductible: deductible,
                premium: premium,
                expiryDate: expiryDate,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PoliciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({propertyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (propertyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.propertyId,
                                referencedTable: $$PoliciesTableReferences
                                    ._propertyIdTable(db),
                                referencedColumn: $$PoliciesTableReferences
                                    ._propertyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PoliciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PoliciesTable,
      Policy,
      $$PoliciesTableFilterComposer,
      $$PoliciesTableOrderingComposer,
      $$PoliciesTableAnnotationComposer,
      $$PoliciesTableCreateCompanionBuilder,
      $$PoliciesTableUpdateCompanionBuilder,
      (Policy, $$PoliciesTableReferences),
      Policy,
      PrefetchHooks Function({bool propertyId})
    >;
typedef $$MaintenanceLogsTableCreateCompanionBuilder =
    MaintenanceLogsCompanion Function({
      required String id,
      Value<String?> itemId,
      Value<String?> propertyId,
      required String title,
      Value<String?> description,
      Value<double?> cost,
      required DateTime performedAt,
      Value<DateTime?> nextDueAt,
      Value<String?> servicedBy,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$MaintenanceLogsTableUpdateCompanionBuilder =
    MaintenanceLogsCompanion Function({
      Value<String> id,
      Value<String?> itemId,
      Value<String?> propertyId,
      Value<String> title,
      Value<String?> description,
      Value<double?> cost,
      Value<DateTime> performedAt,
      Value<DateTime?> nextDueAt,
      Value<String?> servicedBy,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$MaintenanceLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $MaintenanceLogsTable, MaintenanceLog> {
  $$MaintenanceLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.maintenanceLogs.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager? get itemId {
    final $_column = $_itemColumn<String>('item_id');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PropertiesTable _propertyIdTable(_$AppDatabase db) =>
      db.properties.createAlias(
        $_aliasNameGenerator(db.maintenanceLogs.propertyId, db.properties.id),
      );

  $$PropertiesTableProcessedTableManager? get propertyId {
    final $_column = $_itemColumn<String>('property_id');
    if ($_column == null) return null;
    final manager = $$PropertiesTableTableManager(
      $_db,
      $_db.properties,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_propertyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MaintenanceLogsTableFilterComposer
    extends Composer<_$AppDatabase, $MaintenanceLogsTable> {
  $$MaintenanceLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicedBy => $composableBuilder(
    column: $table.servicedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PropertiesTableFilterComposer get propertyId {
    final $$PropertiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableFilterComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $MaintenanceLogsTable> {
  $$MaintenanceLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cost => $composableBuilder(
    column: $table.cost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicedBy => $composableBuilder(
    column: $table.servicedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PropertiesTableOrderingComposer get propertyId {
    final $$PropertiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableOrderingComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaintenanceLogsTable> {
  $$MaintenanceLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<DateTime> get performedAt => $composableBuilder(
    column: $table.performedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);

  GeneratedColumn<String> get servicedBy => $composableBuilder(
    column: $table.servicedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PropertiesTableAnnotationComposer get propertyId {
    final $$PropertiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.propertyId,
      referencedTable: $db.properties,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PropertiesTableAnnotationComposer(
            $db: $db,
            $table: $db.properties,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MaintenanceLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MaintenanceLogsTable,
          MaintenanceLog,
          $$MaintenanceLogsTableFilterComposer,
          $$MaintenanceLogsTableOrderingComposer,
          $$MaintenanceLogsTableAnnotationComposer,
          $$MaintenanceLogsTableCreateCompanionBuilder,
          $$MaintenanceLogsTableUpdateCompanionBuilder,
          (MaintenanceLog, $$MaintenanceLogsTableReferences),
          MaintenanceLog,
          PrefetchHooks Function({bool itemId, bool propertyId})
        > {
  $$MaintenanceLogsTableTableManager(
    _$AppDatabase db,
    $MaintenanceLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaintenanceLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaintenanceLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaintenanceLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<String?> propertyId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double?> cost = const Value.absent(),
                Value<DateTime> performedAt = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<String?> servicedBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceLogsCompanion(
                id: id,
                itemId: itemId,
                propertyId: propertyId,
                title: title,
                description: description,
                cost: cost,
                performedAt: performedAt,
                nextDueAt: nextDueAt,
                servicedBy: servicedBy,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> itemId = const Value.absent(),
                Value<String?> propertyId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<double?> cost = const Value.absent(),
                required DateTime performedAt,
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<String?> servicedBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MaintenanceLogsCompanion.insert(
                id: id,
                itemId: itemId,
                propertyId: propertyId,
                title: title,
                description: description,
                cost: cost,
                performedAt: performedAt,
                nextDueAt: nextDueAt,
                servicedBy: servicedBy,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MaintenanceLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, propertyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$MaintenanceLogsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$MaintenanceLogsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (propertyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.propertyId,
                                referencedTable:
                                    $$MaintenanceLogsTableReferences
                                        ._propertyIdTable(db),
                                referencedColumn:
                                    $$MaintenanceLogsTableReferences
                                        ._propertyIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MaintenanceLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MaintenanceLogsTable,
      MaintenanceLog,
      $$MaintenanceLogsTableFilterComposer,
      $$MaintenanceLogsTableOrderingComposer,
      $$MaintenanceLogsTableAnnotationComposer,
      $$MaintenanceLogsTableCreateCompanionBuilder,
      $$MaintenanceLogsTableUpdateCompanionBuilder,
      (MaintenanceLog, $$MaintenanceLogsTableReferences),
      MaintenanceLog,
      PrefetchHooks Function({bool itemId, bool propertyId})
    >;
typedef $$VideoAnalysesTableCreateCompanionBuilder =
    VideoAnalysesCompanion Function({
      required String id,
      required String videoPath,
      Value<String?> roomId,
      required String status,
      Value<String?> providerTier,
      Value<int> frameCount,
      Value<int> itemsDetected,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$VideoAnalysesTableUpdateCompanionBuilder =
    VideoAnalysesCompanion Function({
      Value<String> id,
      Value<String> videoPath,
      Value<String?> roomId,
      Value<String> status,
      Value<String?> providerTier,
      Value<int> frameCount,
      Value<int> itemsDetected,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$VideoAnalysesTableFilterComposer
    extends Composer<_$AppDatabase, $VideoAnalysesTable> {
  $$VideoAnalysesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerTier => $composableBuilder(
    column: $table.providerTier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frameCount => $composableBuilder(
    column: $table.frameCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemsDetected => $composableBuilder(
    column: $table.itemsDetected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VideoAnalysesTableOrderingComposer
    extends Composer<_$AppDatabase, $VideoAnalysesTable> {
  $$VideoAnalysesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerTier => $composableBuilder(
    column: $table.providerTier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frameCount => $composableBuilder(
    column: $table.frameCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemsDetected => $composableBuilder(
    column: $table.itemsDetected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VideoAnalysesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VideoAnalysesTable> {
  $$VideoAnalysesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get providerTier => $composableBuilder(
    column: $table.providerTier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frameCount => $composableBuilder(
    column: $table.frameCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get itemsDetected => $composableBuilder(
    column: $table.itemsDetected,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$VideoAnalysesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VideoAnalysesTable,
          VideoAnalyse,
          $$VideoAnalysesTableFilterComposer,
          $$VideoAnalysesTableOrderingComposer,
          $$VideoAnalysesTableAnnotationComposer,
          $$VideoAnalysesTableCreateCompanionBuilder,
          $$VideoAnalysesTableUpdateCompanionBuilder,
          (
            VideoAnalyse,
            BaseReferences<_$AppDatabase, $VideoAnalysesTable, VideoAnalyse>,
          ),
          VideoAnalyse,
          PrefetchHooks Function()
        > {
  $$VideoAnalysesTableTableManager(_$AppDatabase db, $VideoAnalysesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VideoAnalysesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VideoAnalysesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VideoAnalysesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> videoPath = const Value.absent(),
                Value<String?> roomId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> providerTier = const Value.absent(),
                Value<int> frameCount = const Value.absent(),
                Value<int> itemsDetected = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideoAnalysesCompanion(
                id: id,
                videoPath: videoPath,
                roomId: roomId,
                status: status,
                providerTier: providerTier,
                frameCount: frameCount,
                itemsDetected: itemsDetected,
                startedAt: startedAt,
                completedAt: completedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String videoPath,
                Value<String?> roomId = const Value.absent(),
                required String status,
                Value<String?> providerTier = const Value.absent(),
                Value<int> frameCount = const Value.absent(),
                Value<int> itemsDetected = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VideoAnalysesCompanion.insert(
                id: id,
                videoPath: videoPath,
                roomId: roomId,
                status: status,
                providerTier: providerTier,
                frameCount: frameCount,
                itemsDetected: itemsDetected,
                startedAt: startedAt,
                completedAt: completedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VideoAnalysesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VideoAnalysesTable,
      VideoAnalyse,
      $$VideoAnalysesTableFilterComposer,
      $$VideoAnalysesTableOrderingComposer,
      $$VideoAnalysesTableAnnotationComposer,
      $$VideoAnalysesTableCreateCompanionBuilder,
      $$VideoAnalysesTableUpdateCompanionBuilder,
      (
        VideoAnalyse,
        BaseReferences<_$AppDatabase, $VideoAnalysesTable, VideoAnalyse>,
      ),
      VideoAnalyse,
      PrefetchHooks Function()
    >;
typedef $$ProductLookupCacheTableCreateCompanionBuilder =
    ProductLookupCacheCompanion Function({
      required String barcode,
      required String name,
      Value<String?> description,
      Value<String?> brand,
      required DateTime cachedAt,
      Value<int> rowid,
    });
typedef $$ProductLookupCacheTableUpdateCompanionBuilder =
    ProductLookupCacheCompanion Function({
      Value<String> barcode,
      Value<String> name,
      Value<String?> description,
      Value<String?> brand,
      Value<DateTime> cachedAt,
      Value<int> rowid,
    });

class $$ProductLookupCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ProductLookupCacheTable> {
  $$ProductLookupCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductLookupCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductLookupCacheTable> {
  $$ProductLookupCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductLookupCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductLookupCacheTable> {
  $$ProductLookupCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ProductLookupCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductLookupCacheTable,
          ProductLookupCacheData,
          $$ProductLookupCacheTableFilterComposer,
          $$ProductLookupCacheTableOrderingComposer,
          $$ProductLookupCacheTableAnnotationComposer,
          $$ProductLookupCacheTableCreateCompanionBuilder,
          $$ProductLookupCacheTableUpdateCompanionBuilder,
          (
            ProductLookupCacheData,
            BaseReferences<
              _$AppDatabase,
              $ProductLookupCacheTable,
              ProductLookupCacheData
            >,
          ),
          ProductLookupCacheData,
          PrefetchHooks Function()
        > {
  $$ProductLookupCacheTableTableManager(
    _$AppDatabase db,
    $ProductLookupCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductLookupCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductLookupCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductLookupCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> barcode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductLookupCacheCompanion(
                barcode: barcode,
                name: name,
                description: description,
                brand: brand,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String barcode,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                required DateTime cachedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductLookupCacheCompanion.insert(
                barcode: barcode,
                name: name,
                description: description,
                brand: brand,
                cachedAt: cachedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductLookupCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductLookupCacheTable,
      ProductLookupCacheData,
      $$ProductLookupCacheTableFilterComposer,
      $$ProductLookupCacheTableOrderingComposer,
      $$ProductLookupCacheTableAnnotationComposer,
      $$ProductLookupCacheTableCreateCompanionBuilder,
      $$ProductLookupCacheTableUpdateCompanionBuilder,
      (
        ProductLookupCacheData,
        BaseReferences<
          _$AppDatabase,
          $ProductLookupCacheTable,
          ProductLookupCacheData
        >,
      ),
      ProductLookupCacheData,
      PrefetchHooks Function()
    >;
typedef $$LoansTableCreateCompanionBuilder =
    LoansCompanion Function({
      required String id,
      required String itemId,
      required String borrowerName,
      Value<DateTime?> expectedReturnDate,
      Value<String?> notes,
      Value<DateTime?> returnedAt,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$LoansTableUpdateCompanionBuilder =
    LoansCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> borrowerName,
      Value<DateTime?> expectedReturnDate,
      Value<String?> notes,
      Value<DateTime?> returnedAt,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$LoansTableReferences
    extends BaseReferences<_$AppDatabase, $LoansTable, Loan> {
  $$LoansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias($_aliasNameGenerator(db.loans.itemId, db.items.id));

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LoansTableFilterComposer extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedReturnDate => $composableBuilder(
    column: $table.expectedReturnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableOrderingComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedReturnDate => $composableBuilder(
    column: $table.expectedReturnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableAnnotationComposer
    extends Composer<_$AppDatabase, $LoansTable> {
  $$LoansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get borrowerName => $composableBuilder(
    column: $table.borrowerName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expectedReturnDate => $composableBuilder(
    column: $table.expectedReturnDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get returnedAt => $composableBuilder(
    column: $table.returnedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LoansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LoansTable,
          Loan,
          $$LoansTableFilterComposer,
          $$LoansTableOrderingComposer,
          $$LoansTableAnnotationComposer,
          $$LoansTableCreateCompanionBuilder,
          $$LoansTableUpdateCompanionBuilder,
          (Loan, $$LoansTableReferences),
          Loan,
          PrefetchHooks Function({bool itemId})
        > {
  $$LoansTableTableManager(_$AppDatabase db, $LoansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LoansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LoansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LoansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> borrowerName = const Value.absent(),
                Value<DateTime?> expectedReturnDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion(
                id: id,
                itemId: itemId,
                borrowerName: borrowerName,
                expectedReturnDate: expectedReturnDate,
                notes: notes,
                returnedAt: returnedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String borrowerName,
                Value<DateTime?> expectedReturnDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> returnedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LoansCompanion.insert(
                id: id,
                itemId: itemId,
                borrowerName: borrowerName,
                expectedReturnDate: expectedReturnDate,
                notes: notes,
                returnedAt: returnedAt,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LoansTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$LoansTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$LoansTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LoansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LoansTable,
      Loan,
      $$LoansTableFilterComposer,
      $$LoansTableOrderingComposer,
      $$LoansTableAnnotationComposer,
      $$LoansTableCreateCompanionBuilder,
      $$LoansTableUpdateCompanionBuilder,
      (Loan, $$LoansTableReferences),
      Loan,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$AppraisalsTableCreateCompanionBuilder =
    AppraisalsCompanion Function({
      required String id,
      required String itemId,
      required String mode,
      required double value,
      Value<String> currency,
      Value<double> confidence,
      Value<String> sourceUrls,
      required String itemModelKey,
      Value<String> countryCode,
      required int queriedAt,
      required int expiresAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AppraisalsTableUpdateCompanionBuilder =
    AppraisalsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> mode,
      Value<double> value,
      Value<String> currency,
      Value<double> confidence,
      Value<String> sourceUrls,
      Value<String> itemModelKey,
      Value<String> countryCode,
      Value<int> queriedAt,
      Value<int> expiresAt,
      Value<String> nodeId,
      Value<String> hlc,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AppraisalsTableReferences
    extends BaseReferences<_$AppDatabase, $AppraisalsTable, Appraisal> {
  $$AppraisalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) => db.items.createAlias(
    $_aliasNameGenerator(db.appraisals.itemId, db.items.id),
  );

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppraisalsTableFilterComposer
    extends Composer<_$AppDatabase, $AppraisalsTable> {
  $$AppraisalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrls => $composableBuilder(
    column: $table.sourceUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemModelKey => $composableBuilder(
    column: $table.itemModelKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get queriedAt => $composableBuilder(
    column: $table.queriedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppraisalsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppraisalsTable> {
  $$AppraisalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrls => $composableBuilder(
    column: $table.sourceUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemModelKey => $composableBuilder(
    column: $table.itemModelKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get queriedAt => $composableBuilder(
    column: $table.queriedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppraisalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppraisalsTable> {
  $$AppraisalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUrls => $composableBuilder(
    column: $table.sourceUrls,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemModelKey => $composableBuilder(
    column: $table.itemModelKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get queriedAt =>
      $composableBuilder(column: $table.queriedAt, builder: (column) => column);

  GeneratedColumn<int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppraisalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppraisalsTable,
          Appraisal,
          $$AppraisalsTableFilterComposer,
          $$AppraisalsTableOrderingComposer,
          $$AppraisalsTableAnnotationComposer,
          $$AppraisalsTableCreateCompanionBuilder,
          $$AppraisalsTableUpdateCompanionBuilder,
          (Appraisal, $$AppraisalsTableReferences),
          Appraisal,
          PrefetchHooks Function({bool itemId})
        > {
  $$AppraisalsTableTableManager(_$AppDatabase db, $AppraisalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppraisalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppraisalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppraisalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> mode = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> sourceUrls = const Value.absent(),
                Value<String> itemModelKey = const Value.absent(),
                Value<String> countryCode = const Value.absent(),
                Value<int> queriedAt = const Value.absent(),
                Value<int> expiresAt = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppraisalsCompanion(
                id: id,
                itemId: itemId,
                mode: mode,
                value: value,
                currency: currency,
                confidence: confidence,
                sourceUrls: sourceUrls,
                itemModelKey: itemModelKey,
                countryCode: countryCode,
                queriedAt: queriedAt,
                expiresAt: expiresAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String mode,
                required double value,
                Value<String> currency = const Value.absent(),
                Value<double> confidence = const Value.absent(),
                Value<String> sourceUrls = const Value.absent(),
                required String itemModelKey,
                Value<String> countryCode = const Value.absent(),
                required int queriedAt,
                required int expiresAt,
                Value<String> nodeId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppraisalsCompanion.insert(
                id: id,
                itemId: itemId,
                mode: mode,
                value: value,
                currency: currency,
                confidence: confidence,
                sourceUrls: sourceUrls,
                itemModelKey: itemModelKey,
                countryCode: countryCode,
                queriedAt: queriedAt,
                expiresAt: expiresAt,
                nodeId: nodeId,
                hlc: hlc,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppraisalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable: $$AppraisalsTableReferences
                                    ._itemIdTable(db),
                                referencedColumn: $$AppraisalsTableReferences
                                    ._itemIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppraisalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppraisalsTable,
      Appraisal,
      $$AppraisalsTableFilterComposer,
      $$AppraisalsTableOrderingComposer,
      $$AppraisalsTableAnnotationComposer,
      $$AppraisalsTableCreateCompanionBuilder,
      $$AppraisalsTableUpdateCompanionBuilder,
      (Appraisal, $$AppraisalsTableReferences),
      Appraisal,
      PrefetchHooks Function({bool itemId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PropertiesTableTableManager get properties =>
      $$PropertiesTableTableManager(_db, _db.properties);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$StorageContainersTableTableManager get storageContainers =>
      $$StorageContainersTableTableManager(_db, _db.storageContainers);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ItemTagsTableTableManager get itemTags =>
      $$ItemTagsTableTableManager(_db, _db.itemTags);
  $$PhotosTableTableManager get photos =>
      $$PhotosTableTableManager(_db, _db.photos);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$PriceHistoryEntriesTableTableManager get priceHistoryEntries =>
      $$PriceHistoryEntriesTableTableManager(_db, _db.priceHistoryEntries);
  $$PoliciesTableTableManager get policies =>
      $$PoliciesTableTableManager(_db, _db.policies);
  $$MaintenanceLogsTableTableManager get maintenanceLogs =>
      $$MaintenanceLogsTableTableManager(_db, _db.maintenanceLogs);
  $$VideoAnalysesTableTableManager get videoAnalyses =>
      $$VideoAnalysesTableTableManager(_db, _db.videoAnalyses);
  $$ProductLookupCacheTableTableManager get productLookupCache =>
      $$ProductLookupCacheTableTableManager(_db, _db.productLookupCache);
  $$LoansTableTableManager get loans =>
      $$LoansTableTableManager(_db, _db.loans);
  $$AppraisalsTableTableManager get appraisals =>
      $$AppraisalsTableTableManager(_db, _db.appraisals);
}
