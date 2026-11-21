import Testing
@testable import sukitamago

struct MissionCatalogTests {
    @Test func sixMissionsHaveUniqueStableIdentifiersAndCompleteMetadata() {
        #expect(MissionCatalog.all.count == 6)
        #expect(Set(MissionCatalog.all.map(\.id)).count == 6)
        #expect(Set(MissionCatalog.all.map(\.category)) == Set(MissionCategory.allCases))
        for mission in MissionCatalog.all {
            #expect(!mission.title.isEmpty && !mission.introduction.isEmpty && !mission.encouragement.isEmpty)
            #expect(!mission.equipment.isEmpty && !mission.icon.isEmpty && mission.durationMinutes > 0)
        }
    }

    @Test func allAndCategoryFiltersReturnExpectedMissions() {
        #expect(MissionCatalog.missions(in: nil) == MissionCatalog.all)
        for category in MissionCategory.allCases {
            let missions = MissionCatalog.missions(in: category)
            #expect(missions.count == 1)
            #expect(missions.allSatisfy { $0.category == category })
        }
        #expect(MissionCatalog.missions(in: .photo) == [MissionCatalog.photo])
    }

    @Test func onlyPhotoCanRunAndExistingPhotoIdentifierIsPreserved() {
        #expect(MissionCatalog.all.filter(\.canStart).map(\.id) == ["photo.nearby-beauty"])
        #expect(MissionCatalog.all.filter { $0.category != .photo }.allSatisfy { !$0.canStart && $0.execution == .unavailable })
        #expect(SmallExperience.first == MissionCatalog.photo)
        #expect(SmallExperience.first.id == "photo.nearby-beauty")
        #expect(MissionCatalog.photo.durationMinutes == 3)
    }

    @MainActor @Test func unsupportedMissionsCannotEnterPhotoOrReflectionFlow() {
        for mission in MissionCatalog.all where !mission.canStart {
            let state = PhotoMissionState(experience: mission)
            #expect(!state.beginPermissionRequest())
            #expect(!state.beginLoading())
            state.confirm()
            state.selectFeeling(.fun)
            #expect(state.phase == .ready)
            #expect(!state.canFinishReflection && state.reflection == nil)
        }
        let photo = PhotoMissionState(experience: MissionCatalog.photo)
        #expect(photo.beginLoading())
    }
}
