class Doctor {
  final String idDoctor;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String passwordHash;
  final String specialty;
  final String address;
  final String? proof; // Optional field for proof if required
  final String orderNumber;

  Doctor({
    required this.idDoctor,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.passwordHash,
    required this.specialty,
    required this.address,
    required this.orderNumber,
    this.proof,
  });

  // Convert Doctor object to JSON
  Map<String, dynamic> toJson() {
    return {
      'idDoctor': idDoctor,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'passwordHash': passwordHash,
      'specialty': specialty,
      'address': address,
      'proof': proof,
      'orderNumber': orderNumber,
    };
  }

  // Create Doctor object from JSON
  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      idDoctor: json['idDoctor'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      passwordHash: json['passwordHash'],
      specialty: json['specialty'],
      address: json['address'],
      proof: json['proof'],
      orderNumber: json['orderNumber'],
    );
  }
}
