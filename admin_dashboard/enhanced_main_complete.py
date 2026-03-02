import streamlit as st
import requests
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from streamlit_option_menu import option_menu
import json
from PIL import Image
import io
import base64

# Page configuration
st.set_page_config(
    page_title="Enhanced Fertility Services Admin Dashboard",
    page_icon="🏥",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Configuration
API_BASE_URL = "http://backend:8000/api/v1"
ADMIN_TOKEN = st.session_state.get('admin_token', '')

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    .status-active {
        color: #28a745;
        font-weight: bold;
    }
    .status-inactive {
        color: #dc3545;
        font-weight: bold;
    }
    .status-pending {
        color: #ffc107;
        font-weight: bold;
    }
    .status-verified {
        color: #28a745;
        font-weight: bold;
    }
    .status-unverified {
        color: #dc3545;
        font-weight: bold;
    }
    .medical-record-card {
        border: 1px solid #ddd;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background-color: #f9f9f9;
    }
    .doctor-card {
        border: 1px solid #e0e0e0;
        border-radius: 8px;
        padding: 1rem;
        margin: 0.5rem 0;
        background-color: #fafafa;
    }
</style>
""", unsafe_allow_html=True)

# Authentication functions
def authenticate_admin(email, password):
    """Authenticate admin user"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/auth/login",
            json={"email": email, "password": password}
        )
        if response.status_code == 200:
            data = response.json()
            return data.get('access_token')
        return None
    except Exception as e:
        st.error(f"Authentication error: {str(e)}")
        return None

def get_headers():
    """Get authorization headers"""
    return {"Authorization": f"Bearer {ADMIN_TOKEN}"} if ADMIN_TOKEN else {}

# Enhanced API functions
def get_users(skip=0, limit=100):
    """Get users list"""
    try:
        response = requests.get(
            f"{API_BASE_URL}/users/?skip={skip}&limit={limit}",
            headers=get_headers()
        )
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching users: {str(e)}")
        return []

def get_user_details(user_id):
    """Get detailed user information"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/users/{user_id}", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        st.error(f"Error fetching user details: {str(e)}")
        return None

def update_user(user_id, user_data):
    """Update user information"""
    try:
        response = requests.put(
            f"{API_BASE_URL}/admin/users/{user_id}",
            json=user_data,
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error updating user: {str(e)}")
        return False

def delete_user(user_id):
    """Delete user"""
    try:
        response = requests.delete(f"{API_BASE_URL}/admin/users/{user_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting user: {str(e)}")
        return False

def get_user_medical_records(user_id):
    """Get user's medical records"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/users/{user_id}/medical-records", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching medical records: {str(e)}")
        return []

def verify_medical_record(record_id, verification_status, notes=""):
    """Verify or reject medical record"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/medical-records/{record_id}/verify",
            json={"is_verified": verification_status, "verification_notes": notes},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error verifying medical record: {str(e)}")
        return False

def get_hospitals():
    """Get hospitals list"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/hospitals/", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching hospitals: {str(e)}")
        return []

def create_hospital(hospital_data):
    """Create new hospital"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/hospitals/",
            json=hospital_data,
            headers=get_headers()
        )
        return response.status_code == 201
    except Exception as e:
        st.error(f"Error creating hospital: {str(e)}")
        return False

def update_hospital(hospital_id, hospital_data):
    """Update hospital information"""
    try:
        response = requests.put(
            f"{API_BASE_URL}/admin/hospitals/{hospital_id}",
            json=hospital_data,
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error updating hospital: {str(e)}")
        return False

def delete_hospital(hospital_id):
    """Delete hospital"""
    try:
        response = requests.delete(f"{API_BASE_URL}/admin/hospitals/{hospital_id}", headers=get_headers())
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error deleting hospital: {str(e)}")
        return False

def get_hospital_doctors(hospital_id):
    """Get doctors for a specific hospital"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/hospitals/{hospital_id}/doctors", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching hospital doctors: {str(e)}")
        return []

def add_doctor_to_hospital(hospital_id, doctor_data):
    """Add doctor to hospital"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/hospitals/{hospital_id}/doctors",
            json=doctor_data,
            headers=get_headers()
        )
        return response.status_code == 201
    except Exception as e:
        st.error(f"Error adding doctor: {str(e)}")
        return False

def remove_doctor_from_hospital(hospital_id, doctor_id):
    """Remove doctor from hospital"""
    try:
        response = requests.delete(
            f"{API_BASE_URL}/admin/hospitals/{hospital_id}/doctors/{doctor_id}",
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error removing doctor: {str(e)}")
        return False

def verify_user(user_id, verification_status):
    """Verify or unverify user"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/users/{user_id}/verify",
            json={"is_verified": verification_status},
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error verifying user: {str(e)}")
        return False

def toggle_user_status(user_id):
    """Toggle user active status"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/users/{user_id}/toggle-status",
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error toggling user status: {str(e)}")
        return False

def toggle_hospital_verification(hospital_id):
    """Toggle hospital verification status"""
    try:
        response = requests.post(
            f"{API_BASE_URL}/admin/hospitals/{hospital_id}/toggle-verification",
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error toggling hospital verification: {str(e)}")
        return False

def get_dashboard_data():
    """Get dashboard overview data"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/dashboard", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return None
    except Exception as e:
        st.error(f"Error fetching dashboard data: {str(e)}")
        return None

# Dashboard pages
def show_login():
    """Show login page"""
    st.markdown('<h1 class="main-header">🏥 Enhanced Admin Dashboard</h1>', unsafe_allow_html=True)
    
    with st.form("login_form"):
        email = st.text_input("Email", placeholder="admin@fertilityservices.com")
        password = st.text_input("Password", type="password")
        submit = st.form_submit_button("Login", use_container_width=True)
        
        if submit:
            if email and password:
                token = authenticate_admin(email, password)
                if token:
                    st.session_state['admin_token'] = token
                    st.session_state['admin_email'] = email
                    st.success("Login successful!")
                    st.rerun()
                else:
                    st.error("Invalid credentials")
            else:
                st.error("Please enter both email and password")

def show_dashboard():
    """Show main dashboard"""
    st.markdown('<h1 class="main-header">📊 Dashboard Overview</h1>', unsafe_allow_html=True)
    
    # Get dashboard data
    dashboard_data = get_dashboard_data()
    
    if not dashboard_data:
        st.error("Failed to load dashboard data")
        return
    
    # Key metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric(
            "Total Users",
            dashboard_data['users']['total'],
            delta=dashboard_data['users']['new_last_30_days']
        )
    
    with col2:
        st.metric(
            "Total Hospitals",
            dashboard_data['hospitals']['total'],
            delta=dashboard_data['hospitals']['verified']
        )
    
    with col3:
        st.metric(
            "Total Appointments",
            dashboard_data['appointments']['total'],
            delta=dashboard_data['appointments']['new_last_30_days']
        )
    
    with col4:
        st.metric(
            "Total Revenue",
            f"${dashboard_data['payments']['total_revenue']:,.2f}",
            delta=f"{dashboard_data['payments']['success_rate']:.1f}%"
        )
    
    # Charts
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("User Types Distribution")
        user_types = dashboard_data['users']['by_type']
        fig = px.pie(
            values=list(user_types.values()),
            names=list(user_types.keys()),
            title="Users by Type"
        )
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.subheader("Appointment Status")
        appointments = dashboard_data['appointments']
        status_data = {
            'Pending': appointments['pending'],
            'Confirmed': appointments['confirmed'],
            'Completed': appointments['completed']
        }
        fig = px.bar(
            x=list(status_data.keys()),
            y=list(status_data.values()),
            title="Appointments by Status"
        )
        st.plotly_chart(fig, use_container_width=True)

def show_users_management():
    """Enhanced user management with edit, delete, and verification"""
    st.markdown('<h1 class="main-header">👥 Enhanced User Management</h1>', unsafe_allow_html=True)
    
    # Tabs for different user management functions
    tab1, tab2, tab3 = st.tabs(["👥 All Users", "🔍 User Details", "📋 Medical Records"])
    
    with tab1:
        show_users_list()
    
    with tab2:
        show_user_details()
    
    with tab3:
        show_medical_records_verification()

def show_users_list():
    """Show users list with management options"""
    users = get_users()
    
    if not users:
        st.info("No users found")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(users)
    
    # Filters
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        user_type_filter = st.selectbox("Filter by Type", ["All"] + list(df['user_type'].unique()))
    with col2:
        status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
    with col3:
        verified_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Unverified"])
    with col4:
        search_term = st.text_input("Search by name/email")
    
    # Apply filters
    filtered_df = df.copy()
    if user_type_filter != "All":
        filtered_df = filtered_df[filtered_df['user_type'] == user_type_filter]
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['is_active'] == (status_filter == "Active")]
    if verified_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verified_filter == "Verified")]
    if search_term:
        filtered_df = filtered_df[
            filtered_df['first_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['last_name'].str.contains(search_term, case=False, na=False) |
            filtered_df['email'].str.contains(search_term, case=False, na=False)
        ]
    
    # Display users
    st.subheader(f"Users ({len(filtered_df)})")
    
    for _, user in filtered_df.iterrows():
        with st.expander(f"{user['first_name']} {user['last_name']} - {user['email']} ({user['user_type']})"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**Type:** {user['user_type']}")
                st.write(f"**Phone:** {user.get('phone', 'N/A')}")
                st.write(f"**Created:** {user['created_at'][:10]}")
                st.write(f"**Profile Completed:** {'Yes' if user.get('profile_completed', False) else 'No'}")
            
            with col2:
                status_class = "status-active" if user['is_active'] else "status-inactive"
                st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if user['is_active'] else 'Inactive'}</span>", unsafe_allow_html=True)
                
                verified_class = "status-verified" if user['is_verified'] else "status-unverified"
                st.markdown(f"**Verified:** <span class='{verified_class}'>{'Yes' if user['is_verified'] else 'No'}</span>", unsafe_allow_html=True)
                
                if user.get('date_of_birth'):
                    st.write(f"**Date of Birth:** {user['date_of_birth']}")
            
            with col3:
                # Action buttons
                col3a, col3b, col3c = st.columns(3)
                
                with col3a:
                    if st.button(f"Toggle Status", key=f"toggle_user_{user['id']}"):
                        if toggle_user_status(user['id']):
                            st.success("User status updated!")
                            st.rerun()
                        else:
                            st.error("Failed to update user status")
                
                with col3b:
                    verify_text = "Unverify" if user['is_verified'] else "Verify"
                    if st.button(verify_text, key=f"verify_user_{user['id']}"):
                        new_status = not user['is_verified']
                        if verify_user(user['id'], new_status):
                            st.success(f"User {'verified' if new_status else 'unverified'}!")
                            st.rerun()
                        else:
                            st.error("Failed to update verification status")
                
                with col3c:
                    if st.button("🗑️ Delete", key=f"delete_user_{user['id']}", help="Delete user"):
                        if st.session_state.get(f"confirm_delete_{user['id']}", False):
                            if delete_user(user['id']):
                                st.success("User deleted!")
                                st.rerun()
                            else:
                                st.error("Failed to delete user")
                        else:
                            st.session_state[f"confirm_delete_{user['id']}"] = True
                            st.warning("Click again to confirm deletion")

def show_user_details():
    """Show detailed user information with edit capabilities"""
    st.subheader("User Details & Edit")
    
    users = get_users()
    if not users:
        st.info("No users found")
        return
    
    # User selection
    user_options = {f"{user['first_name']} {user['last_name']} ({user['email']})": user['id'] for user in users}
    selected_user_name = st.selectbox("Select User", list(user_options.keys()))
    
    if selected_user_name:
        user_id = user_options[selected_user_name]
        user_details = get_user_details(user_id)
        
        if user_details:
            # Edit form
            with st.form("edit_user_form"):
                st.subheader("Edit User Information")
                
                col1, col2 = st.columns(2)
                
                with col1:
                    first_name = st.text_input("First Name", value=user_details.get('first_name', ''))
                    last_name = st.text_input("Last Name", value=user_details.get('last_name', ''))
                    email = st.text_input("Email", value=user_details.get('email', ''))
                    phone = st.text_input("Phone", value=user_details.get('phone', ''))
                
                with col2:
                    user_type = st.selectbox(
                        "User Type",
                        ["patient", "sperm_donor", "egg_donor", "surrogate", "hospital"],
                        index=["patient", "sperm_donor", "egg_donor", "surrogate", "hospital"].index(user_details.get('user_type', 'patient'))
                    )
                    is_active = st.checkbox("Active", value=user_details.get('is_active', True))
                    is_verified = st.checkbox("Verified", value=user_details.get('is_verified', False))
                    profile_completed = st.checkbox("Profile Completed", value=user_details.get('profile_completed', False))
                
                # Additional fields
                bio = st.text_area("Bio", value=user_details.get('bio', ''))
                address = st.text_area("Address", value=user_details.get('address', ''))
                
                col1, col2, col3 = st.columns(3)
                with col1:
                    city = st.text_input("City", value=user_details.get('city', ''))
                with col2:
                    state = st.text_input("State", value=user_details.get('state', ''))
                with col3:
                    country = st.text_input("Country", value=user_details.get('country', ''))
                
                submit = st.form_submit_button("Update User", use_container_width=True)
                
                if submit:
                    update_data = {
                        "first_name": first_name,
                        "last_name": last_name,
                        "email": email,
                        "phone": phone,
                        "user_type": user_type,
                        "is_active": is_active,
                        "is_verified": is_verified,
                        "profile_completed": profile_completed,
                        "bio": bio,
                        "address": address,
                        "city": city,
                        "state": state,
                        "country": country
                    }
                    
                    if update_user(user_id, update_data):
                        st.success("User updated successfully!")
                        st.rerun()
                    else:
                        st.error("Failed to update user")

def show_medical_records_verification():
    """Show medical records verification for donors and surrogates"""
    st.subheader("Medical Records Verification")
    
    # Get users who are donors or surrogates
    users = get_users()
    donor_surrogate_users = [
        user for user in users 
        if user['user_type'] in ['sperm_donor', 'egg_donor', 'surrogate']
    ]
    
    if not donor_surrogate_users:
        st.info("No donors or surrogates found")
        return
    
    # Filter options
    col1, col2 = st.columns(2)
    with col1:
        user_type_filter = st.selectbox("Filter by Type", ["All", "sperm_donor", "egg_donor", "surrogate"])
    with col2:
        verification_filter = st.selectbox("Filter by Verification Status", ["All", "Verified", "Unverified", "Pending"])
    
    # Apply filters
    filtered_users = donor_surrogate_users
    if user_type_filter != "All":
        filtered_users = [user for user in filtered_users if user['user_type'] == user_type_filter]
    
    st.subheader(f"Medical Records ({len(filtered_users)} users)")
    
    for user in filtered_users:
        with st.expander(f"📋 {user['first_name']} {user['last_name']} - {user['user_type'].replace('_', ' ').title()}"):
            # Get medical records for this user
            medical_records = get_user_medical_records(user['id'])
            
            if not medical_records:
                st.info("No medical records submitted yet")
                continue
            
            st.write(f"**User:** {user['first_name']} {user['last_name']} ({user['email']})")
            st.write(f"**Type:** {user['user_type'].replace('_', ' ').title()}")
            st.write(f"**Total Records:** {len(medical_records)}")
            
            # Display each medical record
            for record in medical_records:
                with st.container():
                    st.markdown('<div class="medical-record-card">', unsafe_allow_html=True)
                    
                    col1, col2, col3 = st.columns([2, 1, 1])
                    
                    with col1:
                        st.write(f"**File:** {record.get('file_name', 'Unknown')}")
                        st.write(f"**Type:** {record.get('record_type', 'other').replace('_', ' ').title()}")
                        st.write(f"**Size:** {record.get('file_size', 0)} bytes")
                        st.write(f"**Uploaded:** {record.get('created_at', '')[:10]}")
                        
                        if record.get('description'):
                            st.write(f"**Description:** {record['description']}")
                    
                    with col2:
                        verification_status = record.get('is_verified', False)
                        status_class = "status-verified" if verification_status else "status-unverified"
                        status_text = "Verified" if verification_status else "Unverified"
                        st.markdown(f"**Status:** <span class='{status_class}'>{status_text}</span>", unsafe_allow_html=True)
                        
                        if record.get('verified_at'):
                            st.write(f"**Verified:** {record['verified_at'][:10]}")
                        
                        if record.get('verification_notes'):
                            st.write(f"**Notes:** {record['verification_notes']}")
                    
                    with col3:
                        # Verification actions
                        if not verification_status:
                            if st.button("✅ Verify", key=f"verify_record_{record['id']}"):
                                notes = st.text_input("Verification Notes (optional)", key=f"verify_notes_{record['id']}")
                                if verify_medical_record(record['id'], True, notes):
                                    st.success("Record verified!")
                                    st.rerun()
                                else:
                                    st.error("Failed to verify record")
                        
                        if st.button("❌ Reject", key=f"reject_record_{record['id']}"):
                            notes = st.text_input("Rejection Reason", key=f"reject_notes_{record['id']}")
                            if notes and verify_medical_record(record['id'], False, notes):
                                st.success("Record rejected!")
                                st.rerun()
                            elif not notes:
                                st.error("Please provide rejection reason")
                            else:
                                st.error("Failed to reject record")
                        
                        # Download link (if file path available)
                        if record.get('file_path'):
                            st.markdown(f"[📥 Download]({record['file_path']})")
                    
                    st.markdown('</div>', unsafe_allow_html=True)

def show_hospitals_management():
    """Enhanced hospital management"""
    st.markdown('<h1 class="main-header">🏥 Enhanced Hospital Management</h1>', unsafe_allow_html=True)
    
    # Tabs for different hospital management functions
    tab1, tab2, tab3 = st.tabs(["🏥 All Hospitals", "➕ Add Hospital", "👨‍⚕️ Manage Doctors"])
    
    with tab1:
        show_hospitals_list()
    
    with tab2:
        show_add_hospital()
    
    with tab3:
        show_manage_doctors()

def show_hospitals_list():
    """Show hospitals list with management options"""
    hospitals = get_hospitals()
    
    if not hospitals:
        st.info("No hospitals found")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(hospitals)
    
    # Filters
    col1, col2, col3 = st.columns(3)
    with col1:
        verification_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Pending"])
    with col2:
        city_filter = st.selectbox("Filter by City", ["All"] + list(df['city'].unique()))
    with col3:
        search_term = st.text_input("Search hospitals")
    
    # Apply filters
    filtered_df = df.copy()
    if verification_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verification_filter == "Verified")]
    if city_filter != "All":
        filtered_df = filtered_df[filtered_df['city'] == city_filter]
    if search_term:
        filtered_df = filtered_df[
            filtered_df['name'].str.contains(search_term, case=False, na=False)
        ]
    
    # Display hospitals
    st.subheader(f"Hospitals ({len(filtered_df)})")
    
    for _, hospital in filtered_df.iterrows():
        with st.expander(f"{hospital['name']} - {hospital['city']}, {hospital['state']}"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**License:** {hospital['license_number']}")
                st.write(f"**Email:** {hospital.get('email', 'N/A')}")
                st.write(f"**Phone:** {hospital.get('phone', 'N/A')}")
                st.write(f"**Rating:** {hospital['rating']}/5.0")
            
            with col2:
                st.write(f"**Address:** {hospital['address']}")
                st.write(f"**City:** {hospital['city']}")
                st.write(f"**State:** {hospital['state']}")
                st.write(f"**Country:** {hospital['country']}")
            
            with col3:
                verified_class = "status-verified" if hospital['is_verified'] else "status-pending"
                st.markdown(f"**Status:** <span class='{verified_class}'>{'Verified' if hospital['is_verified'] else 'Pending'}</span>", unsafe_allow_html=True)
                
                # Action buttons
                col3a, col3b = st.columns(2)
                
                with col3a:
                    if st.button(f"Toggle Verification", key=f"toggle_hospital_{hospital['id']}"):
                        if toggle_hospital_verification(hospital['id']):
                            st.success("Hospital verification updated!")
                            st.rerun()
                        else:
                            st.error("Failed to update hospital verification")
                
                with col3b:
                    if st.button("🗑️ Delete", key=f"delete_hospital_{hospital['id']}", help="Delete hospital"):
                        if st.session_state.get(f"confirm_delete_hospital_{hospital['id']}", False):
                            if delete_hospital(hospital['id']):
                                st.success("Hospital deleted!")
                                st.rerun()
                            else:
                                st.error("Failed to delete hospital")
                        else:
                            st.session_state[f"confirm_delete_hospital_{hospital['id']}"] = True
                            st.warning("Click again to confirm deletion")

def show_add_hospital():
    """Add a new hospital to the system"""
    st.write("Add hospital form implementation here")

def show_manage_doctors():
    """Manage hospital doctors"""
    st.subheader("Manage Hospital Doctors")
    
    hospitals = get_hospitals()
    if not hospitals:
        st.info("No hospitals found")
        return
    
    hospital_options = {f"{hospital['name']} - {hospital['city']}": hospital['id'] for hospital in hospitals}
    selected_hospital_name = st.selectbox("Select Hospital", list(hospital_options.keys()))
    
    if selected_hospital_name:
        hospital_id = hospital_options[selected_hospital_name]
        
        tab1, tab2 = st.tabs(["👨‍⚕️ Current Doctors", "➕ Add Doctor"])
        
        with tab1:
            doctors = get_hospital_doctors(hospital_id)
            
            if not doctors:
                st.info("No doctors found for this hospital")
            else:
                st.subheader(f"Doctors ({len(doctors)})")
                
                for doctor in doctors:
                    with st.container():
                        col1, col2, col3 = st.columns([2, 1, 1])
                        
                        with col1:
                            st.write(f"**Name:** Dr. {doctor.get('first_name', '')} {doctor.get('last_name', '')}")
                            st.write(f"**Email:** {doctor.get('email', 'N/A')}")
                            st.write(f"**Phone:** {doctor.get('phone', 'N/A')}")
                        
                        with col2:
                            st.write(f"**Active:** {'Yes' if doctor.get('is_active', False) else 'No'}")
                            st.write(f"**Verified:** {'Yes' if doctor.get('is_verified', False) else 'No'}")
                        
                        with col3:
                            if st.button("🗑️ Remove", key=f"remove_doctor_{doctor['id']}"):
                                if st.session_state.get(f"confirm_remove_doctor_{doctor['id']}", False):
                                    if remove_doctor_from_hospital(hospital_id, doctor['id']):
                                        st.success("Doctor removed successfully!")
                                        st.session_state[f"confirm_remove_doctor_{doctor['id']}"] = False
                                        st.rerun()
                                    else:
                                        st.error("Failed to remove doctor")
                                else:
                                    st.warning("Click again to confirm removal")
                                    st.session_state[f"confirm_remove_doctor_{doctor['id']}"] = True
        
        with tab2:
            st.write("Add doctor form implementation here")
