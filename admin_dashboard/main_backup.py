import streamlit as st
import requests
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
from streamlit_option_menu import option_menu
import json

# Page configuration
st.set_page_config(
    page_title="Fertility Services Admin Dashboard",
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

# API functions
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

def get_appointments():
    """Get appointments list"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/appointments/all", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching appointments: {str(e)}")
        return []

def get_payments():
    """Get payments list"""
    try:
        response = requests.get(f"{API_BASE_URL}/admin/payments/all", headers=get_headers())
        if response.status_code == 200:
            return response.json()
        return []
    except Exception as e:
        st.error(f"Error fetching payments: {str(e)}")
        return []

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

def send_broadcast_notification(title, message, user_type=None):
    """Send broadcast notification"""
    try:
        data = {"title": title, "message": message}
        if user_type:
            data["user_type"] = user_type
        
        response = requests.post(
            f"{API_BASE_URL}/admin/notifications/broadcast",
            params=data,
            headers=get_headers()
        )
        return response.status_code == 200
    except Exception as e:
        st.error(f"Error sending notification: {str(e)}")
        return False

# Dashboard pages
def show_login():
    """Show login page"""
    st.markdown('<h1 class="main-header">🏥 Admin Dashboard Login</h1>', unsafe_allow_html=True)
    
    with st.form("login_form"):
        email = st.text_input("Email", placeholder="admin@example.com")
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
    
    # Recent activity
    st.subheader("System Health")
    col1, col2, col3 = st.columns(3)
    
    with col1:
        verification_rate = (dashboard_data['hospitals']['verified'] / 
                           dashboard_data['hospitals']['total'] * 100) if dashboard_data['hospitals']['total'] > 0 else 0
        st.metric("Hospital Verification Rate", f"{verification_rate:.1f}%")
    
    with col2:
        active_rate = (dashboard_data['users']['active'] / 
                      dashboard_data['users']['total'] * 100) if dashboard_data['users']['total'] > 0 else 0
        st.metric("User Active Rate", f"{active_rate:.1f}%")
    
    with col3:
        st.metric("Payment Success Rate", f"{dashboard_data['payments']['success_rate']:.1f}%")

def show_users():
    """Show users management"""
    st.markdown('<h1 class="main-header">👥 User Management</h1>', unsafe_allow_html=True)
    
    users = get_users()
    
    if not users:
        st.info("No users found")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(users)
    
    # Filters
    col1, col2, col3 = st.columns(3)
    with col1:
        user_type_filter = st.selectbox("Filter by Type", ["All"] + list(df['user_type'].unique()))
    with col2:
        status_filter = st.selectbox("Filter by Status", ["All", "Active", "Inactive"])
    with col3:
        verified_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Unverified"])
    
    # Apply filters
    filtered_df = df.copy()
    if user_type_filter != "All":
        filtered_df = filtered_df[filtered_df['user_type'] == user_type_filter]
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['is_active'] == (status_filter == "Active")]
    if verified_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verified_filter == "Verified")]
    
    # Display users
    st.subheader(f"Users ({len(filtered_df)})")
    
    for _, user in filtered_df.iterrows():
        with st.expander(f"{user['first_name']} {user['last_name']} - {user['email']}"):
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.write(f"**Type:** {user['user_type']}")
                st.write(f"**Phone:** {user.get('phone', 'N/A')}")
                st.write(f"**Created:** {user['created_at'][:10]}")
            
            with col2:
                status_class = "status-active" if user['is_active'] else "status-inactive"
                st.markdown(f"**Status:** <span class='{status_class}'>{'Active' if user['is_active'] else 'Inactive'}</span>", unsafe_allow_html=True)
                
                verified_class = "status-active" if user['is_verified'] else "status-pending"
                st.markdown(f"**Verified:** <span class='{verified_class}'>{'Yes' if user['is_verified'] else 'No'}</span>", unsafe_allow_html=True)
            
            with col3:
                if st.button(f"Toggle Status", key=f"toggle_user_{user['id']}"):
                    if toggle_user_status(user['id']):
                        st.success("User status updated!")
                        st.rerun()
                    else:
                        st.error("Failed to update user status")

def show_hospitals():
    """Show hospitals management"""
    st.markdown('<h1 class="main-header">🏥 Hospital Management</h1>', unsafe_allow_html=True)
    
    hospitals = get_hospitals()
    
    if not hospitals:
        st.info("No hospitals found")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(hospitals)
    
    # Filters
    col1, col2 = st.columns(2)
    with col1:
        verification_filter = st.selectbox("Filter by Verification", ["All", "Verified", "Pending"])
    with col2:
        city_filter = st.selectbox("Filter by City", ["All"] + list(df['city'].unique()))
    
    # Apply filters
    filtered_df = df.copy()
    if verification_filter != "All":
        filtered_df = filtered_df[filtered_df['is_verified'] == (verification_filter == "Verified")]
    if city_filter != "All":
        filtered_df = filtered_df[filtered_df['city'] == city_filter]
    
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
                verified_class = "status-active" if hospital['is_verified'] else "status-pending"
                st.markdown(f"**Status:** <span class='{verified_class}'>{'Verified' if hospital['is_verified'] else 'Pending'}</span>", unsafe_allow_html=True)
                
                if st.button(f"Toggle Verification", key=f"toggle_hospital_{hospital['id']}"):
                    if toggle_hospital_verification(hospital['id']):
                        st.success("Hospital verification updated!")
                        st.rerun()
                    else:
                        st.error("Failed to update hospital verification")

def show_appointments():
    """Show appointments management"""
    st.markdown('<h1 class="main-header">📅 Appointment Management</h1>', unsafe_allow_html=True)
    
    appointments = get_appointments()
    
    if not appointments:
        st.info("No appointments found")
        return
    
    # Convert to DataFrame
    df = pd.DataFrame(appointments)
    
    # Filters
    col1, col2 = st.columns(2)
    with col1:
        status_filter = st.selectbox("Filter by Status", ["All", "pending", "confirmed", "completed", "cancelled"])
    with col2:
        date_filter = st.date_input("Filter by Date", value=None)
    
    # Apply filters
    filtered_df = df.copy()
    if status_filter != "All":
        filtered_df = filtered_df[filtered_df['status'] == status_filter]
    
    # Display appointments
    st.subheader(f"Appointments ({len(filtered_df)})")
    
    # Summary stats
    col1, col2, col3, col4 = st.columns(4)
    with col1:
        st.metric("Pending", len(filtered_df[filtered_df['status'] == 'pending']))
    with col2:
        st.metric("Confirmed", len(filtered_df[filtered_df['status'] == 'confirmed']))
    with col3:
        st.metric("Completed", len(filtered_df[filtered_df['status'] == 'completed']))
    with col4:
        st.metric("Cancelled", len(filtered_df[filtered_df['status'] == 'cancelled']))
    
    # Display appointments table
    if not filtered_df.empty:
        st.dataframe(
            filtered_df[['id', 'appointment_date', 'status', 'price', 'created_at']],
            use_container_width=True
        )

def show_notifications():
    """Show notifications management"""
    st.markdown('<h1 class="main-header">🔔 Notification Management</h1>', unsafe_allow_html=True)
    
    st.subheader("Send Broadcast Notification")
    
    with st.form("notification_form"):
        title = st.text_input("Notification Title")
        message = st.text_area("Notification Message")
        user_type = st.selectbox("Target User Type", ["All Users", "patient", "sperm_donor", "egg_donor", "surrogate", "hospital"])
        
        submit = st.form_submit_button("Send Notification", use_container_width=True)
        
        if submit:
            if title and message:
                target_type = None if user_type == "All Users" else user_type
                if send_broadcast_notification(title, message, target_type):
                    st.success("Notification sent successfully!")
                else:
                    st.error("Failed to send notification")
            else:
                st.error("Please enter both title and message")

# Main app
def main():
    # Check authentication
    if 'admin_token' not in st.session_state or not st.session_state['admin_token']:
        show_login()
        return
    
    # Sidebar navigation
    with st.sidebar:
        st.title("🏥 Admin Panel")
        st.write(f"Welcome, {st.session_state.get('admin_email', 'Admin')}")
        
        selected = option_menu(
            menu_title=None,
            options=["Dashboard", "Users", "Hospitals", "Appointments", "Notifications", "Logout"],
            icons=["speedometer2", "people", "hospital", "calendar-check", "bell", "box-arrow-right"],
            menu_icon="cast",
            default_index=0,
        )
        
        if selected == "Logout":
            st.session_state.clear()
            st.rerun()
    
    # Show selected page
    if selected == "Dashboard":
        show_dashboard()
    elif selected == "Users":
        show_users()
    elif selected == "Hospitals":
        show_hospitals()
    elif selected == "Appointments":
        show_appointments()
    elif selected == "Notifications":
        show_notifications()

if __name__ == "__main__":
    main()
