// Help screen: educates users about smart features
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('راهنما و ویژگی‌های هوشمند')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            '🔔 یادآورهای قبوض',
            'برنامه به طور خودکار برای قبوض و پرداخت‌های شما یادآوری ارسال می‌کند. می‌توانید فاصله زمانی یادآوری را در تنظیمات تغییر دهید (پیش‌فرض ۳ روز قبل از سررسید).',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '⚠️ هشدارهای بودجه',
            'وقتی از ۹۰٪ یا ۱۰۰٪ بودجه خود استفاده کردید، یک اطلاع‌رسانی دریافت می‌کنید. این به شما کمک می‌کند تا قبل از اتمام بودجه، رفتار مالی خود را تنظیم کنید. در پایان ماه نیز یک خلاصه از عملکرد بودجه‌تان دریافت خواهید کرد.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '💡 پیشنهادهای هوشمند',
            'برنامه الگوهای پرداختی شما را تحلیل می‌کند و اشتراک‌های احتمالی را شناسایی می‌کند. همچنین اگر مبلغ یک قبض نسبت به ماه قبل بیش از ۲۰٪ افزایش یابد، به شما اطلاع می‌دهد.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '🤖 قوانین خودکارسازی',
            'می‌توانید قوانینی برای دسته‌بندی خودکار تراکنش‌ها تعریف کنید. برای مثال: "اگر پرداخت‌گیرنده شامل \'Uber\' باشد، دسته را Transportation قرار بده". برنامه همچنین از یک فرهنگ لغت داخلی برای شناسایی خودکار دسته‌های رایج استفاده می‌کند.',
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '🎯 مشاور مالی',
            'با فعال بودن این ویژگی، برنامه نکات و راهنمایی‌های مفیدی برای بهبود وضعیت مالی شما نمایش می‌دهد. اگر این پیشنهادها را آزاردهنده می‌یابید، می‌توانید آن را در تنظیمات غیرفعال کنید.',
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'یادداشت مهم',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تمام این ویژگی‌ها به صورت محلی و آفلاین کار می‌کنند. هیچ داده‌ای به سرور ارسال نمی‌شود و حریم خصوصی شما محفوظ است. همچنین این ویژگی‌ها برای کاهش مصرف باتری بهینه‌سازی شده‌اند.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'تنظیمات',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'می‌توانید هر یک از این ویژگی‌ها را در قسمت تنظیمات فعال یا غیرفعال کنید. برای دسترسی به تنظیمات، از منوی پایین صفحه به قسمت "تنظیمات" بروید.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
