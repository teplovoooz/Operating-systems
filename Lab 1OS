#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <string>
#include <windows.h>

struct Event
{
    std::string text;

    Event(int i)
    {
        text = "event " + std::to_string(i);
    }
};

class Monitor
{
private:
    std::mutex mutex;
    std::condition_variable condition;
    bool ready;
    Event* data;

public:
    Monitor()
    {
        ready = false;
        data = nullptr;
    }

    bool provide(int i)
    {
        std::unique_lock<std::mutex> lock(mutex);

        if (ready)
        {
            std::cout << "[producer] busy, retry later" << std::endl;
            lock.unlock();
            return false;
        }

        data = new Event(i);
        ready = true;

        std::cout << "[producer] sent " << data->text << std::endl;

        condition.notify_one();
        lock.unlock();

        return true;
    }

    void consume()
    {
        std::unique_lock<std::mutex> lock(mutex);

        while (!ready)
        {
            condition.wait(lock);
        }

        Event* ev = data;
        data = nullptr;
        ready = false;

        std::cout << "[consumer] processed " << ev->text << std::endl;

        delete ev;
        lock.unlock();
    }
};

void producer(Monitor* mon)
{
    int i = 1;

    while (true)
    {
        Sleep(1000);

        if (mon->provide(i))
        {
            i++;
        }
    }
}

void consumer(Monitor* mon)
{
    while (true)
    {
        mon->consume();
    }
}

int main()
{
    Monitor mon;

    std::thread t1(producer, &mon);
    std::thread t2(consumer, &mon);

    t1.join();
    t2.join();

    return 0;
}
