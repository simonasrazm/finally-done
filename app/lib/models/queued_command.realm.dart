// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queued_command.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class QueuedCommandRealm extends _QueuedCommandRealm
    with RealmEntity, RealmObjectBase, RealmObject {
  static var _defaultsSet = false;

  QueuedCommandRealm(
    String id,
    String text,
    String status,
    DateTime createdAt, {
    String? audioPath,
    Iterable<String> photoPaths = const [],
    String? transcription,
    String? errorMessage,
    bool failed = false,
    bool actionNeeded = false,
  }) {
    if (!_defaultsSet) {
      _defaultsSet = RealmObjectBase.setDefaults<QueuedCommandRealm>({
        'failed': false,
        'actionNeeded': false,
      });
    }
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'text', text);
    RealmObjectBase.set(this, 'audioPath', audioPath);
    RealmObjectBase.set<RealmList<String>>(
        this, 'photoPaths', RealmList<String>(photoPaths));
    RealmObjectBase.set(this, 'status', status);
    RealmObjectBase.set(this, 'createdAt', createdAt);
    RealmObjectBase.set(this, 'transcription', transcription);
    RealmObjectBase.set(this, 'errorMessage', errorMessage);
    RealmObjectBase.set(this, 'failed', failed);
    RealmObjectBase.set(this, 'actionNeeded', actionNeeded);
  }

  QueuedCommandRealm._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get text => RealmObjectBase.get<String>(this, 'text') as String;
  @override
  set text(String value) => RealmObjectBase.set(this, 'text', value);

  @override
  String? get audioPath =>
      RealmObjectBase.get<String>(this, 'audioPath') as String?;
  @override
  set audioPath(String? value) => RealmObjectBase.set(this, 'audioPath', value);

  @override
  RealmList<String> get photoPaths =>
      RealmObjectBase.get<String>(this, 'photoPaths') as RealmList<String>;
  @override
  set photoPaths(covariant RealmList<String> value) =>
      throw RealmUnsupportedSetError();

  @override
  String get status => RealmObjectBase.get<String>(this, 'status') as String;
  @override
  set status(String value) => RealmObjectBase.set(this, 'status', value);

  @override
  DateTime get createdAt =>
      RealmObjectBase.get<DateTime>(this, 'createdAt') as DateTime;
  @override
  set createdAt(DateTime value) =>
      RealmObjectBase.set(this, 'createdAt', value);

  @override
  String? get transcription =>
      RealmObjectBase.get<String>(this, 'transcription') as String?;
  @override
  set transcription(String? value) =>
      RealmObjectBase.set(this, 'transcription', value);

  @override
  String? get errorMessage =>
      RealmObjectBase.get<String>(this, 'errorMessage') as String?;
  @override
  set errorMessage(String? value) =>
      RealmObjectBase.set(this, 'errorMessage', value);

  @override
  bool get failed => RealmObjectBase.get<bool>(this, 'failed') as bool;
  @override
  set failed(bool value) => RealmObjectBase.set(this, 'failed', value);

  @override
  bool get actionNeeded =>
      RealmObjectBase.get<bool>(this, 'actionNeeded') as bool;
  @override
  set actionNeeded(bool value) =>
      RealmObjectBase.set(this, 'actionNeeded', value);

  @override
  Stream<RealmObjectChanges<QueuedCommandRealm>> get changes =>
      RealmObjectBase.getChanges<QueuedCommandRealm>(this);

  @override
  Stream<RealmObjectChanges<QueuedCommandRealm>> changesFor(
          [List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<QueuedCommandRealm>(this, keyPaths);

  @override
  QueuedCommandRealm freeze() =>
      RealmObjectBase.freezeObject<QueuedCommandRealm>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'text': text.toEJson(),
      'audioPath': audioPath.toEJson(),
      'photoPaths': photoPaths.toEJson(),
      'status': status.toEJson(),
      'createdAt': createdAt.toEJson(),
      'transcription': transcription.toEJson(),
      'errorMessage': errorMessage.toEJson(),
      'failed': failed.toEJson(),
      'actionNeeded': actionNeeded.toEJson(),
    };
  }

  static EJsonValue _toEJson(QueuedCommandRealm value) => value.toEJson();
  static QueuedCommandRealm _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'text': EJsonValue text,
        'status': EJsonValue status,
        'createdAt': EJsonValue createdAt,
      } =>
        QueuedCommandRealm(
          fromEJson(id),
          fromEJson(text),
          fromEJson(status),
          fromEJson(createdAt),
          audioPath: fromEJson(ejson['audioPath']),
          photoPaths: fromEJson(ejson['photoPaths'], defaultValue: const []),
          transcription: fromEJson(ejson['transcription']),
          errorMessage: fromEJson(ejson['errorMessage']),
          failed: fromEJson(ejson['failed'], defaultValue: false),
          actionNeeded: fromEJson(ejson['actionNeeded'], defaultValue: false),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(QueuedCommandRealm._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
        ObjectType.realmObject, QueuedCommandRealm, 'QueuedCommandRealm', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('text', RealmPropertyType.string),
      SchemaProperty('audioPath', RealmPropertyType.string, optional: true),
      SchemaProperty('photoPaths', RealmPropertyType.string,
          collectionType: RealmCollectionType.list),
      SchemaProperty('status', RealmPropertyType.string),
      SchemaProperty('createdAt', RealmPropertyType.timestamp),
      SchemaProperty('transcription', RealmPropertyType.string, optional: true),
      SchemaProperty('errorMessage', RealmPropertyType.string, optional: true),
      SchemaProperty('failed', RealmPropertyType.bool),
      SchemaProperty('actionNeeded', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
