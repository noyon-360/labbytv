import Foundation
import Testing
@testable import labbytv

struct APIResponseDecodingTests {
    @Test func decodesSuccessEnvelope() throws {
        let json = #"{"success":true,"message":"ok","data":{"accessToken":"a","refreshToken":"r","role":"user","_id":"u1"}}"#
        let response = try JSONDecoder().decode(APIResponse<LoginResponse>.self, from: Data(json.utf8))
        #expect(response.success)
        #expect(response.data?.accessToken == "a")
        #expect(response.data?.id == "u1")
    }

    @Test func watchHistoryUsesStatusInsteadOfSuccess() throws {
        let json = #"{"status":true,"data":{"currentTime":12,"duration":100,"isCompleted":false,"isLoved":true}}"#
        let response = try JSONDecoder().decode(APIResponse<VideoStatus>.self, from: Data(json.utf8))
        #expect(response.success)
        #expect(response.data?.isLoved == true)
    }

    @Test func failureIgnoresUnrelatedDataShape() throws {
        // Login's unverified-OTP 403 sends `{ email }` in data.
        let json = #"{"success":false,"message":"OTP is not verified","data":{"email":"a@b.com"}}"#
        let response = try JSONDecoder().decode(APIResponse<LoginResponse>.self, from: Data(json.utf8))
        #expect(!response.success)
        #expect(response.data == nil)
        #expect(response.errorMessage == "OTP is not verified")
    }

    @Test func errorSourcesWinOverMessage() throws {
        let json = #"{"success":false,"message":"Validation error","errorSources":[{"path":"email","message":"Email is invalid"}]}"#
        let response = try JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: Data(json.utf8))
        #expect(response.errorMessage == "Email is invalid")
    }

    @Test func playURLResponseDecodesLiveAndMovie() throws {
        let live = #"{"data":{},"playUrl":"http://h:80/live/u/p/1.m3u8"}"#
        let liveResponse = try JSONDecoder().decode(PlayURLResponse<EmptyResponse>.self, from: Data(live.utf8))
        #expect(liveResponse.playUrl.hasSuffix(".m3u8"))

        let movie = #"{"data":{"info":{"name":"X","duration_secs":"3600"},"movie_data":{"container_extension":"mkv"}},"playUrl":"http://h/movie/u/p/2.mkv"}"#
        let movieResponse = try JSONDecoder().decode(PlayURLResponse<MovieInfo>.self, from: Data(movie.utf8))
        #expect(movieResponse.info?.durationSecs == 3600)
        #expect(movieResponse.info?.containerExtension == "mkv")
    }
}
