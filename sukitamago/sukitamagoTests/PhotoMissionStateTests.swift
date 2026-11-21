import Testing
import UIKit
@testable import sukitamago

@MainActor
struct PhotoMissionStateTests {
    private var image: UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
        }
    }

    @Test func unavailableAndPermissionErrorsRecover() {
        let state = PhotoMissionState()
        #expect(state.beginPermissionRequest())
        #expect(!state.beginPermissionRequest())
        state.resolveCamera(.unavailable)
        #expect(state.phase == .ready)
        #expect(state.notice != nil)
        #expect(state.beginPermissionRequest())
        state.resolveCamera(.denied)
        #expect(state.notice?.offersSettings == true)
        #expect(state.phase == .ready)
        #expect(state.beginPermissionRequest())
        state.resolveCamera(.restricted)
        #expect(state.notice?.offersSettings == false)
    }

    @Test func cancellationAndBackgroundDoNotComplete() {
        let state = PhotoMissionState()
        state.confirm()
        #expect(state.phase == .ready)
        #expect(state.beginPermissionRequest())
        state.resolveCamera(.available)
        #expect(state.phase == .capturing)
        state.cancelCapture()
        #expect(state.phase == .ready)
        #expect(state.beginPermissionRequest())
        state.interrupt()
        state.resolveCamera(.available)
        #expect(state.phase == .ready)
        #expect(state.beginLoading())
        state.interrupt()
        state.receive(image)
        #expect(state.photo == nil)
        #expect(state.phase == .ready)
    }

    @Test func previewRetakeConfirmShareOneImage() {
        let state = PhotoMissionState()
        let photo = image
        #expect(state.beginLoading())
        #expect(!state.beginLoading())
        state.receive(photo)
        #expect(state.phase == .preview)
        #expect(state.photo === photo)
        state.retake()
        #expect(state.phase == .ready)
        #expect(state.photo == nil)
        #expect(state.beginLoading())
        state.fail("読み込み失敗")
        #expect(state.phase == .ready)
        #expect(state.beginLoading())
        state.receive(photo)
        state.confirm()
        state.confirm()
        #expect(state.phase == .completed)
        #expect(state.photo === photo)
        #expect(!state.beginPermissionRequest())
    }

    @Test func imageLoaderRejectsInvalidDataAndBoundsDecode() async {
        #expect(await MissionPhotoLoader.image(from: Data([0, 1, 2])) == nil)
        let large = UIGraphicsImageRenderer(size: CGSize(width: 3200, height: 1600)).image { _ in }
        let data = large.pngData()!
        let loaded = await MissionPhotoLoader.image(from: data)
        #expect(loaded?.size.width == 2048)
        #expect(loaded?.size.height == 1024)
    }
}
