const API_BASE_URL = "https://zest-dev.sitespectrum.dev/api/Admin";

export interface User {
  id: number;
  userName: string;
  email: string;
  height: number;
  weight: number;
  gender: string;
  goal: string;
  activity: string;
  birth: string;
  profilePicture?: string;
}

const getAuthHeaders = () => {
  const token = localStorage.getItem("admin_token");
  return {
    "Content-Type": "application/json",
    "Authorization": token ? `Bearer ${token}` : "",
  };
};

export const loginAdmin = async (username: string, password: string) => {
  const response = await fetch(`${API_BASE_URL}/login`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      username: username,
      password: password,
    }),
  });

  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || "Hibás felhasználónév vagy jelszó!");
  }

  return response.json(); 
};

export const getUsers = async (): Promise<User[]> => {
  const response = await fetch(`${API_BASE_URL}/users`, {
    headers: getAuthHeaders(),
  });

  if (response.status === 401) {
    throw new Error("unauthorized");
  }
  
  if (!response.ok) {
    throw new Error("Hiba a felhasználók lekérésekor");
  }
  
  return response.json();
};

export const deleteUser = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  
  if (response.status === 401) {
    throw new Error("unauthorized");
  }

  if (!response.ok) {
    throw new Error("Hiba történt a törlés során");
  }
};

export const updateUser = async (id: number, data: Partial<User>): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}`, {
    method: "PUT",
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });

  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a frissítés során");
};

export const removeUserProfilePicture = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}/profile-picture`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });

  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a profilkép törlése során");
};

export interface Exercise {
  id: number;
  name: string;
  name_hu: string;
  category: string;
  category_hu: string;
  equipment: string;
  equipment_hu: string;
  force: string;
  force_hu: string;
  level: string;
  level_hu: string;
  mechanic: string;
  mechanic_hu: string;
  metValue: number;
  primaryMuscles: string[];
  primaryMuscles_hu: string[];
  secondaryMuscles: string[];
  secondaryMuscles_hu: string[];
  instructions: string[];
  instructions_hu: string[];
  images: string[];
}

// === EXERCISES API ===

export const getExercises = async (): Promise<Exercise[]> => {
  const response = await fetch(`${API_BASE_URL}/exercises`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a gyakorlatok lekérésekor");
  return response.json();
};

export const createExercise = async (data: Omit<Exercise, "id">): Promise<Exercise> => {
  const response = await fetch(`${API_BASE_URL}/exercises`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a létrehozás során");
  return response.json();
};

export const updateExercise = async (id: number, data: Exercise): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/exercises/${id}`, {
    method: "PUT",
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a frissítés során");
};

export const deleteExercise = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/exercises/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba történt a törlés során");
};

// === EDZÉSEK ÉS ÉTKEZÉSEK (USER ADATOK) INTERFÉSZEI ===

export interface AdminWorkout {
  id: number;
  userId: number;
  userName: string;
  workoutName: string;
  customName: string;
  date: string;
  durationMinutes: number;
  totalBurntCalories: number;
  isCustom: boolean;
}

export interface AdminMeal {
  id: number;
  userId: number;
  userName: string;
  mealName: string;
  customName: string;
  eatenAt: string;
  totalCalories: number;
  isCustom: boolean;
}

// === EDZÉSEK API ===

export const getAdminWorkouts = async (): Promise<AdminWorkout[]> => {
  const response = await fetch(`${API_BASE_URL}/workouts`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba az edzések lekérésekor");
  return response.json();
};

export const deleteAdminWorkout = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/workouts/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a törlés során");
};

// === ÉTKEZÉSEK API ===

export const getAdminMeals = async (): Promise<AdminMeal[]> => {
  const response = await fetch(`${API_BASE_URL}/meals`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba az étkezések lekérésekor");
  return response.json();
};

export const deleteAdminMeal = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/meals/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a törlés során");
};

// === KÖZÖS EDZÉSEK (SESSIONS) INTERFÉSZ ÉS API ===

export interface AdminSession {
  sessionId: string;
  name: string;
  hostName: string;
  isPublic: boolean;
  createdAt: string;
  status: string;
  participantCount: number;
}

export const getAdminSessions = async (): Promise<AdminSession[]> => {
  const response = await fetch(`${API_BASE_URL}/sessions`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a sessionök lekérésekor");
  return response.json();
};

export const deleteAdminSession = async (sessionId: string): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/sessions/${sessionId}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a törlés során");
};

// === DASHBOARD STATISZTIKA API ===

export interface AdminStats {
  totalUsers: number;
  totalWorkouts: number;
  todayWorkouts: number;
  totalMeals: number;
  todayMeals: number;
  activeSessions: number;
  totalExercises: number;
}

export const getAdminStats = async (): Promise<AdminStats> => {
  const response = await fetch(`${API_BASE_URL}/stats`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a statisztikák lekérésekor");
  return response.json();
};

// === DEEP DIVE INTERFÉSZ ÉS API ===

export interface UserDetails {
  id: number;
  userName: string;
  email: string;
  profilePicture?: string;
  height: number;
  weight: number;
  gender: string;
  goal: string;
  activity: string;
  birth: string;
  friendsCount: number;
  friendsList: string[];
  totalWorkouts: number;
  totalMeals: number;
  recentWorkouts: {
    id: number;
    workoutName: string;
    customName: string;
    date: string;
    durationMinutes: number;
    totalBurntCalories: number;
  }[];
  recentMeals: {
    id: number;
    mealName: string;
    customName: string;
    eatenAt: string;
    totalCalories: number;
    totalProtein: number;
    totalCarbs: number;
    totalFat: number;
  }[];
}

export const getUserDetails = async (id: number): Promise<UserDetails> => {
  const response = await fetch(`${API_BASE_URL}/users/${id}/details`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a felhasználó részleteinek lekérésekor");
  return response.json();
};

// === ÉRTESÍTÉSEK (NOTIFICATIONS) API ===

export const sendGlobalNotification = async (title: string, message: string): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/notifications/broadcast`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify({ title, message }),
  });

  if (response.status === 401) throw new Error("unauthorized");
  
  if (!response.ok) {
    const errorData = await response.json().catch(() => ({}));
    throw new Error(errorData.message || "Hiba az értesítés küldésekor");
  }
};

// === GLOBÁLIS EDZÉSTERVEK API ===

export interface AdminTemplate {
  id: number;
  customName: string;
  durationMinutes: number;
  totalBurntCalories: number;
  exerciseCount: number;
  exercises: {
    exerciseId: number;
    nameHu: string;
    setsCount: number;
  }[];
}

export interface CreateTemplatePayload {
  customName: string;
  durationMinutes: number;
  caloriesBurnt: number;
  exercises: {
    exerciseId: number;
    sets: { weight: number; reps: number }[];
  }[];
}

export const getAdminTemplates = async (): Promise<AdminTemplate[]> => {
  const response = await fetch(`${API_BASE_URL}/templates`, { headers: getAuthHeaders() });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a sablonok lekérésekor");
  return response.json();
};

export const createAdminTemplate = async (data: CreateTemplatePayload): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/templates`, {
    method: "POST",
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a létrehozás során");
};

export const deleteAdminTemplate = async (id: number): Promise<void> => {
  const response = await fetch(`${API_BASE_URL}/templates/${id}`, {
    method: "DELETE",
    headers: getAuthHeaders(),
  });
  if (response.status === 401) throw new Error("unauthorized");
  if (!response.ok) throw new Error("Hiba a törlés során");
};