import { useState } from 'react';
import {
    BarChart3, Package, Users, ShoppingCart, Calendar,
    Bell, Settings, TrendingUp, Gift, Mail, Zap
} from 'lucide-react';

export const Admin = () => {
    const [activeTab, setActiveTab] = useState('dashboard');

    const stats = [
        { label: 'Total Sales', value: 'Rs 125,450', change: '+12.5%', icon: TrendingUp, color: 'bg-green-500' },
        { label: 'Orders', value: '48', change: '+8.2%', icon: ShoppingCart, color: 'bg-blue-500' },
        { label: 'Customers', value: '234', change: '+15.3%', icon: Users, color: 'bg-purple-500' },
        { label: 'Products', value: '156', change: '+5', icon: Package, color: 'bg-orange-500' },
    ];

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white border-b border-gray-200 sticky top-0 z-10">
                <div className="px-6 py-4">
                    <div className="flex items-center justify-between">
                        <div>
                            <h1 className="text-2xl font-bold text-gray-900">Admin Dashboard</h1>
                            <p className="text-sm text-gray-500">Nab Makeup & Skincare</p>
                        </div>
                        <div className="flex items-center space-x-4">
                            <button
                                className="relative p-2 text-gray-600 hover:bg-gray-100 rounded-lg"
                                title="Notifications"
                                aria-label="View notifications"
                            >
                                <Bell size={20} />
                                <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
                            </button>
                            <div className="flex items-center space-x-3">
                                <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center text-white font-bold">
                                    N
                                </div>
                                <div>
                                    <p className="text-sm font-medium">Nabila Ahmad</p>
                                    <p className="text-xs text-gray-500">Administrator</p>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            <div className="flex">
                {/* Sidebar */}
                <aside className="w-64 bg-white border-r border-gray-200 min-h-screen">
                    <nav className="p-4 space-y-2">
                        {[
                            { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
                            { id: 'promotions', label: 'Promotions', icon: Gift, badge: 'NEW' },
                            { id: 'products', label: 'Products', icon: Package },
                            { id: 'orders', label: 'Orders', icon: ShoppingCart },
                            { id: 'customers', label: 'Customers', icon: Users },
                            { id: 'bookings', label: 'Bookings', icon: Calendar },
                            { id: 'automation', label: 'N8N Automation', icon: Zap, badge: 'PRO' },
                            { id: 'settings', label: 'Settings', icon: Settings },
                        ].map((item) => (
                            <button
                                key={item.id}
                                onClick={() => setActiveTab(item.id)}
                                className={`w-full flex items-center justify-between px-4 py-3 rounded-lg transition-colors ${activeTab === item.id
                                    ? 'bg-secondary text-white'
                                    : 'text-gray-700 hover:bg-gray-100'
                                    }`}
                            >
                                <div className="flex items-center space-x-3">
                                    <item.icon size={20} />
                                    <span className="font-medium">{item.label}</span>
                                </div>
                                {item.badge && (
                                    <span className="text-xs bg-yellow-400 text-black px-2 py-0.5 rounded-full font-bold">
                                        {item.badge}
                                    </span>
                                )}
                            </button>
                        ))}
                    </nav>
                </aside>

                {/* Main Content */}
                <main className="flex-1 p-8">
                    {activeTab === 'dashboard' && (
                        <div className="space-y-6">
                            {/* Stats Grid */}
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                                {stats.map((stat, index) => (
                                    <div key={index} className="bg-white p-6 rounded-xl border border-gray-200">
                                        <div className="flex items-center justify-between mb-4">
                                            <div className={`${stat.color} p-3 rounded-lg text-white`}>
                                                <stat.icon size={24} />
                                            </div>
                                            <span className="text-green-600 text-sm font-semibold">{stat.change}</span>
                                        </div>
                                        <h3 className="text-2xl font-bold text-gray-900">{stat.value}</h3>
                                        <p className="text-sm text-gray-500">{stat.label}</p>
                                    </div>
                                ))}
                            </div>

                            {/* Quick Actions */}
                            <div className="bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl p-6 text-white">
                                <h2 className="text-2xl font-bold mb-2">🎄 Christmas & New Year Promotion</h2>
                                <p className="mb-4 opacity-90">Create special offers for the holiday season</p>
                                <button
                                    onClick={() => setActiveTab('promotions')}
                                    className="bg-white text-purple-600 px-6 py-2 rounded-lg font-semibold hover:bg-gray-100 transition-colors"
                                >
                                    Create Promotion
                                </button>
                            </div>

                            {/* Recent Activity */}
                            <div className="bg-white rounded-xl border border-gray-200 p-6">
                                <h3 className="text-lg font-bold mb-4">Recent Orders</h3>
                                <div className="space-y-3">
                                    {[
                                        { customer: 'Sarah Johnson', product: 'ABIB Sunstick', amount: 'Rs 995', status: 'Completed' },
                                        { customer: 'Mike Chen', product: 'Differin Gel', amount: 'Rs 1,500', status: 'Processing' },
                                        { customer: 'Emma Wilson', product: 'Bridal Makeup', amount: 'Rs 5,000', status: 'Pending' },
                                    ].map((order, index) => (
                                        <div key={index} className="flex items-center justify-between py-3 border-b border-gray-100 last:border-0">
                                            <div>
                                                <p className="font-medium">{order.customer}</p>
                                                <p className="text-sm text-gray-500">{order.product}</p>
                                            </div>
                                            <div className="text-right">
                                                <p className="font-semibold">{order.amount}</p>
                                                <span className={`text-xs px-2 py-1 rounded-full ${order.status === 'Completed' ? 'bg-green-100 text-green-700' :
                                                    order.status === 'Processing' ? 'bg-blue-100 text-blue-700' :
                                                        'bg-yellow-100 text-yellow-700'
                                                    }`}>
                                                    {order.status}
                                                </span>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'promotions' && (
                        <div className="space-y-6">
                            <div className="flex items-center justify-between">
                                <h2 className="text-2xl font-bold">Promotion Management</h2>
                                <button className="bg-secondary text-white px-6 py-2 rounded-lg font-semibold hover:bg-secondary/90">
                                    + Create New Promotion
                                </button>
                            </div>

                            {/* Active Promotions */}
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                {/* Christmas Sale */}
                                <div className="bg-white rounded-xl border-2 border-red-200 p-6">
                                    <div className="flex items-start justify-between mb-4">
                                        <div className="flex items-center space-x-3">
                                            <div className="bg-red-100 p-3 rounded-lg">
                                                <Gift className="text-red-600" size={24} />
                                            </div>
                                            <div>
                                                <h3 className="font-bold text-lg">Christmas Sale 2024</h3>
                                                <p className="text-sm text-gray-500">25% OFF All Products</p>
                                            </div>
                                        </div>
                                        <span className="bg-green-100 text-green-700 text-xs px-3 py-1 rounded-full font-semibold">
                                            Active
                                        </span>
                                    </div>
                                    <div className="space-y-2 text-sm">
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Start Date:</span>
                                            <span className="font-medium">Dec 20, 2024</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">End Date:</span>
                                            <span className="font-medium">Dec 26, 2024</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Discount Code:</span>
                                            <span className="font-mono font-bold">XMAS25</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Uses:</span>
                                            <span className="font-medium">24 / Unlimited</span>
                                        </div>
                                    </div>
                                    <div className="mt-4 pt-4 border-t border-gray-200 flex space-x-2">
                                        <button className="flex-1 bg-gray-100 text-gray-700 py-2 rounded-lg font-medium hover:bg-gray-200">
                                            Edit
                                        </button>
                                        <button className="flex-1 bg-red-50 text-red-600 py-2 rounded-lg font-medium hover:bg-red-100">
                                            Deactivate
                                        </button>
                                    </div>
                                </div>

                                {/* New Year Sale */}
                                <div className="bg-white rounded-xl border-2 border-purple-200 p-6">
                                    <div className="flex items-start justify-between mb-4">
                                        <div className="flex items-center space-x-3">
                                            <div className="bg-purple-100 p-3 rounded-lg">
                                                <Gift className="text-purple-600" size={24} />
                                            </div>
                                            <div>
                                                <h3 className="font-bold text-lg">New Year Promo</h3>
                                                <p className="text-sm text-gray-500">Buy 2 Get 1 Free</p>
                                            </div>
                                        </div>
                                        <span className="bg-yellow-100 text-yellow-700 text-xs px-3 py-1 rounded-full font-semibold">
                                            Scheduled
                                        </span>
                                    </div>
                                    <div className="space-y-2 text-sm">
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Start Date:</span>
                                            <span className="font-medium">Dec 31, 2024</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">End Date:</span>
                                            <span className="font-medium">Jan 7, 2025</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Discount Code:</span>
                                            <span className="font-mono font-bold">NEWYEAR2025</span>
                                        </div>
                                        <div className="flex justify-between">
                                            <span className="text-gray-600">Auto-Email:</span>
                                            <span className="font-medium text-green-600">✓ Enabled</span>
                                        </div>
                                    </div>
                                    <div className="mt-4 pt-4 border-t border-gray-200 flex space-x-2">
                                        <button className="flex-1 bg-gray-100 text-gray-700 py-2 rounded-lg font-medium hover:bg-gray-200">
                                            Edit
                                        </button>
                                        <button className="flex-1 bg-green-50 text-green-600 py-2 rounded-lg font-medium hover:bg-green-100">
                                            Activate Now
                                        </button>
                                    </div>
                                </div>
                            </div>

                            {/* Promotion Templates */}
                            <div className="bg-white rounded-xl border border-gray-200 p-6">
                                <h3 className="text-lg font-bold mb-4">Quick Templates</h3>
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                                    {[
                                        { name: 'Flash Sale', desc: '24-hour limited offer', icon: '⚡' },
                                        { name: 'BOGO', desc: 'Buy One Get One', icon: '🎁' },
                                        { name: 'Free Shipping', desc: 'No delivery fee', icon: '🚚' },
                                    ].map((template, index) => (
                                        <button key={index} className="p-4 border-2 border-dashed border-gray-300 rounded-lg hover:border-purple-400 hover:bg-purple-50 transition-all text-left">
                                            <div className="text-3xl mb-2">{template.icon}</div>
                                            <h4 className="font-semibold">{template.name}</h4>
                                            <p className="text-sm text-gray-500">{template.desc}</p>
                                        </button>
                                    ))}
                                </div>
                            </div>
                        </div>
                    )}

                    {activeTab === 'automation' && (
                        <div className="space-y-6">
                            <div className="flex items-center justify-between">
                                <div>
                                    <h2 className="text-2xl font-bold">N8N Automation</h2>
                                    <p className="text-gray-500">Automate your business workflows</p>
                                </div>
                                <button className="bg-gradient-to-r from-purple-600 to-pink-600 text-white px-6 py-2 rounded-lg font-semibold hover:shadow-lg">
                                    + New Workflow
                                </button>
                            </div>

                            {/* Active Workflows */}
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                {[
                                    {
                                        name: 'Booking Confirmation',
                                        description: 'Auto-send email when booking is made',
                                        trigger: 'New Booking',
                                        actions: ['Send Email', 'Add to Calendar', 'SMS Reminder'],
                                        status: 'Active',
                                        runs: '156',
                                    },
                                    {
                                        name: 'Low Stock Alert',
                                        description: 'Notify when product stock is low',
                                        trigger: 'Stock < 5',
                                        actions: ['Email Admin', 'Create Task'],
                                        status: 'Active',
                                        runs: '23',
                                    },
                                    {
                                        name: 'Promotion Email Campaign',
                                        description: 'Send promo emails to customer list',
                                        trigger: 'Scheduled Daily',
                                        actions: ['Fetch Customers', 'Send Bulk Email', 'Track Opens'],
                                        status: 'Paused',
                                        runs: '8',
                                    },
                                    {
                                        name: 'Order Fulfillment',
                                        description: 'Process orders and update inventory',
                                        trigger: 'Payment Confirmed',
                                        actions: ['Update Stock', 'Generate Invoice', 'Notify Customer'],
                                        status: 'Active',
                                        runs: '89',
                                    },
                                ].map((workflow, index) => (
                                    <div key={index} className="bg-white rounded-xl border border-gray-200 p-6 hover:shadow-lg transition-shadow">
                                        <div className="flex items-start justify-between mb-4">
                                            <div className="flex items-center space-x-3">
                                                <div className="bg-gradient-to-br from-purple-500 to-pink-500 p-3 rounded-lg text-white">
                                                    <Zap size={20} />
                                                </div>
                                                <div>
                                                    <h3 className="font-bold">{workflow.name}</h3>
                                                    <p className="text-sm text-gray-500">{workflow.description}</p>
                                                </div>
                                            </div>
                                            <span className={`text-xs px-3 py-1 rounded-full font-semibold ${workflow.status === 'Active'
                                                ? 'bg-green-100 text-green-700'
                                                : 'bg-gray-100 text-gray-700'
                                                }`}>
                                                {workflow.status}
                                            </span>
                                        </div>
                                        <div className="space-y-2 text-sm mb-4">
                                            <div className="flex items-center space-x-2">
                                                <span className="text-gray-600">Trigger:</span>
                                                <span className="bg-blue-100 text-blue-700 px-2 py-0.5 rounded">{workflow.trigger}</span>
                                            </div>
                                            <div>
                                                <span className="text-gray-600">Actions:</span>
                                                <div className="flex flex-wrap gap-1 mt-1">
                                                    {workflow.actions.map((action, i) => (
                                                        <span key={i} className="bg-purple-100 text-purple-700 px-2 py-0.5 rounded text-xs">
                                                            {action}
                                                        </span>
                                                    ))}
                                                </div>
                                            </div>
                                            <div className="flex items-center space-x-2">
                                                <span className="text-gray-600">Runs:</span>
                                                <span className="font-semibold">{workflow.runs}</span>
                                            </div>
                                        </div>
                                        <div className="flex space-x-2">
                                            <button className="flex-1 bg-gray-100 text-gray-700 py-2 rounded-lg text-sm font-medium hover:bg-gray-200">
                                                Edit
                                            </button>
                                            <button className="flex-1 bg-purple-50 text-purple-600 py-2 rounded-lg text-sm font-medium hover:bg-purple-100">
                                                View Logs
                                            </button>
                                        </div>
                                    </div>
                                ))}
                            </div>

                            {/* N8N Integration Info */}
                            <div className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-xl border border-purple-200 p-6">
                                <div className="flex items-start space-x-4">
                                    <div className="bg-white p-3 rounded-lg">
                                        <Mail size={24} className="text-purple-600" />
                                    </div>
                                    <div className="flex-1">
                                        <h3 className="font-bold text-lg mb-2">N8N Webhook URL</h3>
                                        <p className="text-sm text-gray-600 mb-3">
                                            Connect your N8N instance to receive real-time events
                                        </p>
                                        <div className="bg-white p-3 rounded-lg border border-gray-200 font-mono text-sm">
                                            https://n8n.nabmakeup.com/webhook/bookings
                                        </div>
                                        <button className="mt-3 bg-purple-600 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-purple-700">
                                            Test Connection
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}

                    {/* Placeholder for other tabs */}
                    {!['dashboard', 'promotions', 'automation'].includes(activeTab) && (
                        <div className="bg-white rounded-xl border border-gray-200 p-12 text-center">
                            <div className="text-6xl mb-4">🚧</div>
                            <h3 className="text-xl font-bold mb-2">Coming Soon</h3>
                            <p className="text-gray-500">This section is under development</p>
                        </div>
                    )}
                </main>
            </div>
        </div>
    );
};
