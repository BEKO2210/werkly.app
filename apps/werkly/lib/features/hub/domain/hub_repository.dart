import 'package:werkly/features/hub/domain/hub_models.dart';

abstract class HubRepository {
  Future<Hub?> getHubForUser(String userId);
  Future<Hub?> getHubBySlug(String slug);
  Future<Hub> getOrCreateHub({
    required String userId,
    String displayName,
  });
  Future<Hub> saveHub(Hub hub);
  Future<HubLink> upsertLink(HubLink link);
  Future<void> deleteLink(String linkId);
  Future<Hub> reorderLinks(String hubId, List<String> orderedLinkIds);
  Future<MediaKit?> getMediaKitForHub(String hubId);
  Future<MediaKit> saveMediaKit(MediaKit kit);
  Future<List<HubLinkClickStats>> linkStats(String hubId);
  String shareUrlFor(Hub hub);
  String mediaKitShareUrl(MediaKit kit);
}
