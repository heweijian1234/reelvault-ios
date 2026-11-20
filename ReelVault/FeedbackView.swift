import SwiftUI
import MessageUI

// MARK: - 用户反馈页（健哥 11-20 令加；同 HyperLog/GroomerBook 改法——邮箱统一 zerone348+无邮件账户回退）
struct FeedbackView: View {
    @State private var text = ""
    @State private var showMail = false
    @State private var mailAvailable = MFMailComposeViewController.canSendMail()

    var body: some View {
        Form {
            Section("告诉我们你的想法") {
                TextField("什么好用、什么不好用、你希望有什么——开发者每条都看。", text: $text, axis: .vertical)
                    .lineLimit(6...14)
            }
            Section {
                Button {
                    if mailAvailable {
                        showMail = true
                    } else {
                        // 未配系统邮件账户：mailto 直跳回退（正文 URL 转义仅此兜底路径）
                        let subject = "ReelVault Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let body = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
                        if let url = URL(string: "mailto:zerone348@gmail.com?subject=\(subject)&body=\(body)") {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Label("发给开发者", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.teal)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if !mailAvailable {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("本机未配邮件账户——反馈请发到：")
                            .font(.caption).foregroundColor(.secondary)
                        Text("zerone348@gmail.com")
                            .font(.body.bold())
                            .textSelection(.enabled)
                    }
                }
            } footer: {
                Text("有问题抱歉！请告诉开发者哪里不好用——会尽快修。新功能想法也非常欢迎，让 App 更好用。")
            }
        }
        .navigationTitle("反馈")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMail) {
            MailComposer(body: text)
        }
    }
}

struct MailComposer: UIViewControllerRepresentable {
    let body: String
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let m = MFMailComposeViewController()
        m.setToRecipients(["zerone348@gmail.com"])
        m.setSubject("ReelVault Feedback")
        m.setMessageBody(body, isHTML: false)
        m.mailComposeDelegate = context.coordinator
        return m
    }
    func updateUIViewController(_ vc: MFMailComposeViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
