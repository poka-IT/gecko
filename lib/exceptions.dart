class NotMemberException implements Exception {
  final String? message;

  const NotMemberException([this.message]);

  @override
  String toString() {
    if (message == null || message!.isEmpty) {
      return "The user is not a member.";
    }
    return message!;
  }
}

class CantBeCertException implements Exception {
  final String message;

  const CantBeCertException(this.message);

  @override
  String toString() => "Cannot be certified.\nStatus: $message";
}
