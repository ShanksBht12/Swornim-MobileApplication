const UserType = {
  CLIENT: "client",
  PHOTOGRAPHER: "photographer",
  MAKEUP_ARTIST: "makeup_artist",
  DECORATOR: "decorator",
  VENUE: "venue",
  CATERER: "caterer",
  EVENT_ORGANIZER: "event_organizer",
};

const UserStatus = {
  PENDING: "pending",
  APPROVED: "approved",
  ACTIVE: "active",
  SUSPENDED: "suspended",
  REJECTED: "rejected",
  INACTIVE: "inactive",
};

const Gender = {
  MALE: "male",
  FEMALE: "female",
  OTHERS: "others",
};

const TokenType = {
  ACCESS: "access",
  REFRESH: "refresh",
};

module.exports = {
  UserType,
  UserStatus,
  Gender,
  TokenType,
};
